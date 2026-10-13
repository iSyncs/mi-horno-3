// ChallengesViewModel.swift
import SwiftUI
import Combine

#if canImport(FoundationModels)
import FoundationModels
#endif

enum ERROR_GENERACION_IA: Error {
    case MODELO_NO_DISPONIBLE(String)
    case CONTEXTO_NO_DISPONIBLE
    case RESPUESTA_INCOMPLETA
    case PREGUNTAS_INSUFICIENTES

    var DESCRIPCION: String {
        switch self {
        case .MODELO_NO_DISPONIBLE(let RAZON):
            return "Apple Intelligence no está disponible: \(RAZON)"
        case .CONTEXTO_NO_DISPONIBLE:
            return "No se encontró el contexto local para esta zona."
        case .RESPUESTA_INCOMPLETA:
            return "La pregunta generada no tiene cuatro opciones válidas."
        case .PREGUNTAS_INSUFICIENTES:
            return "La trivia generada no contiene 5 preguntas válidas."
        }
    }
}

enum ChallengeFlow: Identifiable {
    case quiz(ChallengeDefinition)
    case cameraPrep(ChallengeDefinition)
    case camera(ChallengeDefinition)

    var id: String {
        switch self {
        case .quiz(let challenge): return "quiz_\(challenge.id)"
        case .cameraPrep(let challenge): return "cameraPrep_\(challenge.id)"
        case .camera(let challenge): return "camera_\(challenge.id)"
        }
    }
}

struct RawChallenge: Codable {
    let challenge_id: String
    let zone_id: Int
    let question: String
    let options: [String]
    let correct_answer: String
    let type: String
}

struct PREGUNTA_TRIVIA_GENERADA_LOCAL: Codable, Hashable {
    let USER_ID: Int
    let QUIZ_ID: String
    let CHALLENGE_ID: String
    let ZONE_ID: Int
    let QUESTION: String
    let OPTIONS: [String]
    let CORRECT_ANSWER: String
    let TYPE: String
    let CREATED_AT: String

    enum CodingKeys: String, CodingKey {
        case USER_ID = "user_id"
        case QUIZ_ID = "quiz_id"
        case CHALLENGE_ID = "challenge_id"
        case ZONE_ID = "zone_id"
        case QUESTION = "question"
        case OPTIONS = "options"
        case CORRECT_ANSWER = "correct_answer"
        case TYPE = "type"
        case CREATED_AT = "created_at"
    }
}

final class ChallengesViewModel: ObservableObject {
    @AppStorage("EDAD_USUARIO") private var EDAD_USUARIO: Int = 18
    @AppStorage("DISCAPACIDAD_MOTRIZ") private var DISCAPACIDAD_MOTRIZ: Bool = false
    @AppStorage("GENERO_USUARIO") private var GENERO_USUARIO: String = "Prefiero no decirlo"

    @Published var selectedZone: ChallengeZone = .general
    @Published var challenges: [ChallengeDefinition] = []
    @Published var expandedZone: ChallengeZone? = nil
    @Published var activeFlow: ChallengeFlow? = nil
    @Published var GENERANDO_PREGUNTA_IA: Bool = false
    @Published var ERROR_PREGUNTA_IA: String? = nil
    @Published var PREGUNTAS_IA_GENERADAS: [PREGUNTA_TRIVIA_GENERADA_LOCAL] = []

    @Published var currentQuestionIndex: Int = 0
    @Published var currentAnswers: [String: Int] = [:]
    @Published var selectedAnswerIndex: Int? = nil
    @Published var isCurrentQuestionChecked: Bool = false

    @Published var zoneXP: [ChallengeZone: Int] = [:]
    @Published var completedChallengeIDs: Set<String> = []
    @Published var unlockedZones: Set<ChallengeZone> = ChallengeCatalog.defaultUnlockedZones

    // Vision / Camera Integration
    @Published var visionService = VisionService()
    @Published var cameraManager = CameraManager()
    @Published var activeCameraMission: CameraMission? = nil
    @Published var isObjectDetected: Bool = false
    @Published var detectedLabel: String = ""
    @Published var detectionConfidence: Float = 0.0
    @Published var topDetections: [VisionService.ClassificationResult] = []

    @Published var newlyUnlockedBadge: String? = nil
    @Published var showBadgeUnlock: Bool = false

    private var allQuizQuestionsByZone: [ChallengeZone: [ChallengeQuestion]] = [:]
    private let baseURL = Config.baseURL
    private let LIMITE_PREGUNTAS_IA_POR_ZONA = 50
    private let PREGUNTAS_POR_QUIZ_IA = 5

    private var USER_ID_ACTUAL: Int {
        UserDefaults.standard.integer(forKey: "h3_user_id")
    }

    private var zoneXPKey: String { "h3_zone_xp_v2_\(USER_ID_ACTUAL)" }
    private var completedChallengesKey: String { "h3_completed_challenge_ids_v2_\(USER_ID_ACTUAL)" }
    private var unlockedZonesKey: String { "h3_unlocked_zone_ids_v2_\(USER_ID_ACTUAL)" }
    private var unlockedBadgesKey: String { "h3_unlocked_badges_v2_\(USER_ID_ACTUAL)" }
    private var pendingQueueKey: String { "com.horno3.pending_challenges_\(USER_ID_ACTUAL)" }
    
    private var lmCancellable: AnyCancellable?
    private var visionCancellables = Set<AnyCancellable>()

    init() {
        loadState()
        CARGAR_PREGUNTAS_IA_GENERADAS()
        reloadChallenges()
        setupVisionBindings()
        processPendingQueue()
        loadBackendHistory()
        CARGAR_TRIVIA_IA_BACKEND()
        
        lmCancellable = LocalizationManager.shared.$t
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadChallenges()
            }
    }

    private func setupVisionBindings() {
        visionService.$classificationLabel
            .sink { [weak self] label in
                self?.detectedLabel = label
                self?.checkDetection()
            }
            .store(in: &visionCancellables)

        visionService.$confidence
            .sink { [weak self] conf in
                self?.detectionConfidence = conf
                self?.checkDetection()
            }
            .store(in: &visionCancellables)

        visionService.$topClassifications
            .receive(on: DispatchQueue.main)
            .assign(to: &$topDetections)
    }

    private func checkDetection() {
        guard let activeCameraMission else { return }
        
        let expectedID = normalizedClassifierLabel(activeCameraMission.classifierLabel)
        let label = normalizedClassifierLabel(detectedLabel)
        
        if label == expectedID {
            if !isObjectDetected {
                withAnimation(.spring()) {
                    isObjectDetected = true
                }
            }
        } else {
            if isObjectDetected {
                withAnimation(.spring()) {
                    isObjectDetected = false
                }
            }
        }
    }

    func processCameraFrame(_ buffer: CVPixelBuffer) {
        visionService.classify(image: buffer)
    }

    var activeChallenge: ChallengeDefinition? {
        switch activeFlow {
        case .quiz(let challenge), .cameraPrep(let challenge), .camera(let challenge):
            return challenge
        case nil:
            return nil
        }
    }

    var currentQuestion: ChallengeQuestion? {
        guard let activeChallenge,
              activeChallenge.questions.indices.contains(currentQuestionIndex)
        else { return nil }
        return activeChallenge.questions[currentQuestionIndex]
    }

    var totalChallenges: Int {
        ChallengeZone.allCases.reduce(0) { TOTAL, ZONA in
            TOTAL + CAPACIDAD_DESAFIOS_ZONA(for: ZONA)
        }
    }
    
    var completedChallengesCount: Int {
        ChallengeZone.allCases.reduce(0) { TOTAL, ZONA in
            TOTAL + UNIDADES_COMPLETADAS(for: ZONA)
        }
    }

    var overallProgressFraction: Double {
        let total = totalChallenges
        guard total > 0 else { return 0 }
        return Double(completedChallengesCount) / Double(total)
    }

    var unlockedZonesCount: Int { unlockedZones.count }

    var quizProgressFraction: Double {
        guard let activeChallenge, !activeChallenge.questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(activeChallenge.questions.count)
    }

    var hasAnsweredCurrentQuestion: Bool {
        selectedAnswerIndex != nil
    }

    var activeChallengeCorrectCount: Int {
        guard let activeChallenge else { return 0 }
        return activeChallenge.questions.reduce(into: 0) { partialResult, question in
            if currentAnswers[question.id] == question.correctIndex {
                partialResult += 1
            }
        }
    }

    func xpForZone(_ zone: ChallengeZone) -> Int {
        zoneXP[zone] ?? 0
    }

    func rankForZone(_ zone: ChallengeZone) -> String {
        let xp = xpForZone(zone)
        if xp >= zone.xpGold { return "Oro" }
        if xp >= zone.xpSilver { return "Plata" }
        if xp >= zone.xpBronze { return "Bronce" }
        return "Novato"
    }

    func progressForZone(_ zone: ChallengeZone) -> Double {
        let TOTAL = CAPACIDAD_DESAFIOS_ZONA(for: zone)
        guard TOTAL > 0 else { return 0 }
        return min(Double(UNIDADES_COMPLETADAS(for: zone)) / Double(TOTAL), 1)
    }

    func ZONA_COMPLETADA(_ zone: ChallengeZone) -> Bool {
        progressForZone(zone) >= 1
    }

    func PUEDE_GENERAR_TRIVIA(for zone: ChallengeZone) -> Bool {
        !ZONA_COMPLETADA(zone) && CONTEO_PREGUNTAS_IA_GENERADAS(for: zone) < LIMITE_PREGUNTAS_IA_POR_ZONA
    }

    func CONTEO_PREGUNTAS_IA_GENERADAS(for zone: ChallengeZone) -> Int {
        PREGUNTAS_IA_GENERADAS.filter { $0.ZONE_ID == zone.databaseID }.count
    }

    func CAPACIDAD_DESAFIOS_ZONA(for zone: ChallengeZone) -> Int {
        LIMITE_PREGUNTAS_IA_POR_ZONA + cameraMissions(for: zone).count
    }

    private func UNIDADES_COMPLETADAS(for zone: ChallengeZone) -> Int {
        let PREGUNTAS_COMPLETADAS = min(CONTEO_TRIVIA_COMPLETADA(for: zone), LIMITE_PREGUNTAS_IA_POR_ZONA)
        let CAMARAS_COMPLETADAS = cameraMissions(for: zone).filter { completedChallengeIDs.contains($0.challengeID) }.count
        return PREGUNTAS_COMPLETADAS + CAMARAS_COMPLETADAS
    }

    private func CONTEO_TRIVIA_COMPLETADA(for zone: ChallengeZone) -> Int {
        let IDS_ESTATICOS = Set(allQuizQuestionsByZone[zone]?.map(\.id) ?? [])
        let IDS_GENERADOS = Set(PREGUNTAS_IA_GENERADAS.filter { $0.ZONE_ID == zone.databaseID }.map(\.CHALLENGE_ID))
        let PREFIJO_IA = "\(zone.PREFIJO_TRIVIA_GENERADA)-IA-"
        let IDS_IA_REMOTOS = completedChallengeIDs.filter { $0.hasPrefix(PREFIJO_IA) }
        return completedChallengeIDs.intersection(IDS_ESTATICOS.union(IDS_GENERADOS).union(IDS_IA_REMOTOS)).count
    }

    func reloadChallenges() {
        // 1. Cargar datos del JSON
        guard let url = Bundle.main.url(forResource: "trivia_data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rawChallenges = try? JSONDecoder().decode([RawChallenge].self, from: data) else {
            return
        }

        var newChallenges: [ChallengeDefinition] = []
        let zones: [ChallengeZone] = [.general, .history, .steelGallery]

        for zone in zones {
            let zoneID = zone.databaseID

            // Filtramos las preguntas del JSON para esta zona
            let zoneQuestions = rawChallenges.filter { $0.zone_id == zoneID && $0.type == "quiz" }
            
            if !zoneQuestions.isEmpty {
                let questions = zoneQuestions.map { raw in
                    ChallengeQuestion(
                        id: raw.challenge_id,
                        text: raw.question,
                        options: raw.options,
                        correctIndex: raw.options.firstIndex(of: raw.correct_answer) ?? 0,
                        explanation: ""
                    )
                }
                allQuizQuestionsByZone[zone] = questions

                // Creamos el reto de Trivia para la zona (5 preguntas al azar)
                let remainingQuestions = questions.filter { !completedChallengeIDs.contains($0.id) }
                newChallenges.append(ChallengeDefinition(
                    id: "quiz_\(zone.rawValue)",
                    zone: zone,
                    kind: .quiz,
                    title: "Trivia \(zone.rawValue.capitalized)",
                    subtitle: "Reto de conocimientos",
                    icon: zone.icon,
                    estimatedMinutes: 5,
                    xpReward: 250,
                    questions: Array(remainingQuestions.shuffled().prefix(5))
                ))
            }
        }

        let cameraChallenges = CameraMissionRepository.missions(lm: LocalizationManager.shared).map { mission in
            ChallengeDefinition(
                id: mission.challengeID,
                zone: mission.zone,
                kind: .camera,
                title: mission.title,
                subtitle: mission.description,
                icon: mission.icon,
                estimatedMinutes: 2,
                xpReward: 500,
                questions: []
            )
        }
        newChallenges.append(contentsOf: cameraChallenges)

        self.challenges = newChallenges
    }

    private func generateHistoryChallenge(from base: ChallengeDefinition) -> ChallengeDefinition {
        let randomQuestions = Array(TriviaRepository.historyQuestions(lm: LocalizationManager.shared).shuffled().prefix(5))
        return ChallengeDefinition(
            id: base.id,
            zone: base.zone,
            kind: base.kind,
            title: base.title,
            subtitle: base.subtitle,
            icon: base.icon,
            estimatedMinutes: base.estimatedMinutes,
            xpReward: base.xpReward,
            questions: randomQuestions
        )
    }

    func startNewHistoryTrivia() {
        if let historyChallenge = challenges.first(where: { $0.zone == .history && $0.kind == .quiz }) {
            selectFlow(.quiz(historyChallenge))
        }
    }

    func INICIAR_TRIVIA_IA(ZONA: ChallengeZone) {
        guard !GENERANDO_PREGUNTA_IA else { return }
        guard !ZONA_COMPLETADA(ZONA) else {
            ERROR_PREGUNTA_IA = "Ya completaste todos los desafíos de esta zona."
            return
        }

        if let DESAFIO_PENDIENTE = DESAFIO_IA_PENDIENTE(ZONA: ZONA) {
            selectFlow(.quiz(DESAFIO_PENDIENTE))
            return
        }

        guard PUEDE_GENERAR_TRIVIA(for: ZONA) else {
            ERROR_PREGUNTA_IA = "Ya generaste el máximo de 50 preguntas para esta zona."
            return
        }

        Task {
            do {
                try await GENERAR_PREGUNTA_IA(ZONA: ZONA.rawValue)
            } catch let ERROR {
                await MainActor.run {
                    if let ERROR_IA = ERROR as? ERROR_GENERACION_IA {
                        ERROR_PREGUNTA_IA = ERROR_IA.DESCRIPCION
                    } else {
                        ERROR_PREGUNTA_IA = ERROR.localizedDescription
                    }
                    GENERANDO_PREGUNTA_IA = false
                }
            }
        }
    }

    @MainActor
    func GENERAR_PREGUNTA_IA(ZONA: String) async throws {
        GENERANDO_PREGUNTA_IA = true
        ERROR_PREGUNTA_IA = nil
        defer { GENERANDO_PREGUNTA_IA = false }

        let ZONA_TRIVIA = ChallengeZone(rawValue: ZONA) ?? .general
        let CONTEXTO_ZONA = GESTOR_CONTEXTO.OBTENER_CONTEXTO_ZONA(ZONA: ZONA)
        guard !CONTEXTO_ZONA.isEmpty else {
            throw ERROR_GENERACION_IA.CONTEXTO_NO_DISPONIBLE
        }

        #if canImport(FoundationModels)
        let MODELO = SystemLanguageModel.default
        switch MODELO.availability {
        case .available:
            break
        case .unavailable(let RAZON):
            throw ERROR_GENERACION_IA.MODELO_NO_DISPONIBLE(String(describing: RAZON))
        }

        let NOTA_ACCESIBILIDAD = DISCAPACIDAD_MOTRIZ
        ? "El visitante tiene movilidad reducida, no incluyas preguntas que impliquen desplazamientos físicos o posturas complejas."
        : ""

        let PROMPT_SISTEMA = """
        Eres un guía experto del Museo Horno 3. Genera EXACTAMENTE \(PREGUNTAS_POR_QUIZ_IA) preguntas de trivia de opción múltiple usando ÚNICAMENTE el banco de hechos siguiente: \(CONTEXTO_ZONA)

        Reglas obligatorias:
        - Usa un hecho distinto para cada pregunta.
        - Alterna formatos: fecha, causa, consecuencia, comparación, función, identificación, cantidad o lugar.
        - No hagas dos preguntas con la misma estructura verbal.
        - No preguntes siempre "Qué es..." o "En qué año...".
        - OPCIONES debe contener exactamente 4 respuestas.
        - RESPUESTA_CORRECTA debe coincidir textualmente con una de las opciones.
        - Los distractores deben ser plausibles, pero claramente incorrectos según el banco de hechos.
        - No inventes datos, nombres, años, cantidades ni lugares.
        - No uses datos que no aparezcan explícitamente en el banco de hechos.
        - El visitante tiene \(EDAD_USUARIO) años. Adapta el lenguaje a su edad.
        - Su género registrado es \(GENERO_USUARIO). No hagas suposiciones por género.
        \(NOTA_ACCESIBILIDAD)
        """

        let SESION = LanguageModelSession(instructions: PROMPT_SISTEMA)
        let RESPUESTA = try await SESION.respond(
            to: "Genera un quiz nuevo de \(PREGUNTAS_POR_QUIZ_IA) preguntas para la zona \(ZONA).",
            generating: PREGUNTAS_TRIVIA.self
        )
        let PREGUNTAS_GENERADAS = RESPUESTA.content.PREGUNTAS
        let NUMERO_QUIZ = (CONTEO_PREGUNTAS_IA_GENERADAS(for: ZONA_TRIVIA) / PREGUNTAS_POR_QUIZ_IA) + 1
        let QUIZ_ID = "\(ZONA_TRIVIA.PREFIJO_TRIVIA_GENERADA)-IA-QUIZ-\(String(format: "%03d", NUMERO_QUIZ))"
        let FECHA_CREACION = ISO8601DateFormatter().string(from: Date())
        let PREGUNTAS_VALIDAS = try PREGUNTAS_GENERADAS.prefix(PREGUNTAS_POR_QUIZ_IA).enumerated().map { INDICE, PREGUNTA_GENERADA in
            let OPCIONES_VALIDAS = Array(PREGUNTA_GENERADA.OPCIONES.prefix(4))
            guard OPCIONES_VALIDAS.count == 4,
                  let INDICE_CORRECTO = OPCIONES_VALIDAS.firstIndex(of: PREGUNTA_GENERADA.RESPUESTA_CORRECTA) else {
                throw ERROR_GENERACION_IA.RESPUESTA_INCOMPLETA
            }

            let NUMERO_PREGUNTA = ((NUMERO_QUIZ - 1) * PREGUNTAS_POR_QUIZ_IA) + INDICE + 1
            let CHALLENGE_ID = "\(ZONA_TRIVIA.PREFIJO_TRIVIA_GENERADA)-IA-\(String(format: "%03d", NUMERO_PREGUNTA))"
            return ChallengeQuestion(
                id: CHALLENGE_ID,
                text: PREGUNTA_GENERADA.PREGUNTA,
                options: OPCIONES_VALIDAS,
                correctIndex: INDICE_CORRECTO,
                explanation: "Generada con Apple Intelligence usando el contexto local del Museo Horno 3."
            )
        }

        guard PREGUNTAS_VALIDAS.count == PREGUNTAS_POR_QUIZ_IA else {
            throw ERROR_GENERACION_IA.PREGUNTAS_INSUFICIENTES
        }

        let PREGUNTAS_LOCALES = PREGUNTAS_VALIDAS.map { PREGUNTA in
            PREGUNTA_TRIVIA_GENERADA_LOCAL(
                USER_ID: USER_ID_ACTUAL,
                QUIZ_ID: QUIZ_ID,
                CHALLENGE_ID: PREGUNTA.id,
                ZONE_ID: ZONA_TRIVIA.databaseID,
                QUESTION: PREGUNTA.text,
                OPTIONS: PREGUNTA.options,
                CORRECT_ANSWER: PREGUNTA.options[PREGUNTA.correctIndex],
                TYPE: "quiz",
                CREATED_AT: FECHA_CREACION
            )
        }

        PREGUNTAS_IA_GENERADAS.append(contentsOf: PREGUNTAS_LOCALES)
        GUARDAR_PREGUNTAS_IA_GENERADAS()
        ENVIAR_QUIZ_GENERADO_BACKEND(PREGUNTAS: PREGUNTAS_LOCALES)

        let DESAFIO = ChallengeDefinition(
            id: QUIZ_ID,
            zone: ZONA_TRIVIA,
            kind: .quiz,
            title: "Trivia IA \(ZONA_TRIVIA.rawValue.capitalized)",
            subtitle: "Desafío infinito por IA",
            icon: ZONA_TRIVIA.icon,
            estimatedMinutes: 5,
            xpReward: 250,
            questions: PREGUNTAS_VALIDAS
        )

        selectFlow(.quiz(DESAFIO))
        #else
        throw ERROR_GENERACION_IA.MODELO_NO_DISPONIBLE("FoundationModels no está disponible en este SDK.")
        #endif
    }

    func startNewCameraMission(for zone: ChallengeZone) {
        let remainingMissions = cameraMissions(for: zone).filter { !completedChallengeIDs.contains($0.challengeID) }
        guard let mission = remainingMissions.shuffled().first else { return }
        startCameraMission(mission)
    }

    func startCameraMission(_ mission: CameraMission) {
        guard !completedChallengeIDs.contains(mission.challengeID) else { return }
        
        activeCameraMission = mission
        isObjectDetected = false
        detectedLabel = ""
        detectionConfidence = 0
        topDetections = []
        
        if let challenge = challenges.first(where: { $0.id == mission.challengeID }) {
            selectFlow(.cameraPrep(challenge))
        }
    }

    func cameraMissions(for zone: ChallengeZone) -> [CameraMission] {
        CameraMissionRepository.missions(lm: LocalizationManager.shared).filter { $0.zone == zone }
    }

    func isCameraMissionCompleted(_ mission: CameraMission) -> Bool {
        completedChallengeIDs.contains(mission.challengeID)
    }

    func remainingQuizQuestionsCount(for zone: ChallengeZone) -> Int {
        (allQuizQuestionsByZone[zone] ?? []).filter { !completedChallengeIDs.contains($0.id) }.count
    }

    func isZoneUnlocked(_ zone: ChallengeZone) -> Bool {
        unlockedZones.contains(zone)
    }

    func isCompleted(_ challenge: ChallengeDefinition) -> Bool {
        completedChallengeIDs.contains(challenge.id)
    }

    func selectFlow(_ flow: ChallengeFlow) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            currentQuestionIndex = 0
            currentAnswers = [:]
            selectedAnswerIndex = nil
            isCurrentQuestionChecked = false
            activeFlow = flow
        }
    }

    func selectAnswer(_ index: Int, questionID: String) {
        guard !isCurrentQuestionChecked else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
            selectedAnswerIndex = index
            currentAnswers[questionID] = index
        }
    }

    func checkCurrentAnswer() {
        guard selectedAnswerIndex != nil else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            isCurrentQuestionChecked = true
        }
    }

    func continueQuiz(totalQuestions: Int, challenge: ChallengeDefinition) {
        let nextIndex = currentQuestionIndex + 1

        if nextIndex < totalQuestions {
            withAnimation(.easeInOut(duration: 0.22)) {
                currentQuestionIndex = nextIndex
                selectedAnswerIndex = nil
                isCurrentQuestionChecked = false
            }
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentQuestionIndex = totalQuestions
                selectedAnswerIndex = nil
                isCurrentQuestionChecked = false
            }
        }
    }

    func completeChallenge(_ challenge: ChallengeDefinition) {
        withAnimation(.spring()) {
            let previousCount = completedChallengesCount
            let newlyCompletedIDs: [String]
            if challenge.kind == .quiz {
                newlyCompletedIDs = challenge.questions.map(\.id).filter { !completedChallengeIDs.contains($0) }
                completedChallengeIDs.formUnion(newlyCompletedIDs)
            } else if let activeCameraMission {
                newlyCompletedIDs = completedChallengeIDs.contains(activeCameraMission.challengeID) ? [] : [activeCameraMission.challengeID]
                completedChallengeIDs.formUnion(newlyCompletedIDs)
            } else {
                newlyCompletedIDs = completedChallengeIDs.contains(challenge.id) ? [] : [challenge.id]
                completedChallengeIDs.formUnion(newlyCompletedIDs)
            }
            let newCount = completedChallengesCount

            if !newlyCompletedIDs.isEmpty {
                let oldXP = zoneXP[challenge.zone] ?? 0
                let newXP = oldXP + challenge.xpReward
                zoneXP[challenge.zone] = newXP
                
                checkBadgeUnlock(zone: challenge.zone, oldXP: oldXP, newXP: newXP)
                checkMasterBadgeUnlock(oldCount: previousCount, newCount: newCount)
            }
            
            sendCompletionsToBackend(
                challengeIDs: newlyCompletedIDs,
                zone: challenge.zone,
                kind: challenge.kind,
                totalXP: challenge.xpReward
            )

            saveState()
            currentQuestionIndex = 0
            currentAnswers = [:]
            selectedAnswerIndex = nil
            isCurrentQuestionChecked = false
            activeFlow = nil
            activeCameraMission = nil
            
            // Recargamos retos
            reloadChallenges()
            objectWillChange.send()
        }
    }

    func leaveFlow() {
        withAnimation {
            activeFlow = nil
            activeCameraMission = nil
            currentQuestionIndex = 0
            currentAnswers = [:]
            selectedAnswerIndex = nil
            isCurrentQuestionChecked = false
        }
    }

    func resetAllProgress() {
        withAnimation {
            currentQuestionIndex = 0
            currentAnswers = [:]
            selectedAnswerIndex = nil
            isCurrentQuestionChecked = false
            zoneXP = [:]
            completedChallengeIDs = []
            expandedZone = nil
            activeFlow = nil
            activeCameraMission = nil
        }

        UserDefaults.standard.removeObject(forKey: completedChallengesKey)
        UserDefaults.standard.removeObject(forKey: zoneXPKey)
    }

    func unlockZone(_ zone: ChallengeZone) {
        unlockedZones.insert(zone)
        saveUnlockedZones()
    }

    func resetZone(_ zone: ChallengeZone) {
        // We only reset total xp and completed challenge IDs from THIS zone.
        let IDS_ESTATICOS = availableChallengeIDs(for: zone)
        let IDS_IA = completedChallengeIDs.filter { $0.hasPrefix("\(zone.PREFIJO_TRIVIA_GENERADA)-IA-") }
        let IDS_A_REMOVER = IDS_ESTATICOS.union(IDS_IA)
        
        var newCompleted = completedChallengeIDs
        newCompleted.subtract(IDS_A_REMOVER)
        completedChallengeIDs = newCompleted
        
        var newXP = zoneXP
        newXP[zone] = 0
        zoneXP = newXP

        currentQuestionIndex = 0
        currentAnswers = [:]
        selectedAnswerIndex = nil
        isCurrentQuestionChecked = false
        activeFlow = nil
        activeCameraMission = nil
        ERROR_PREGUNTA_IA = nil
        PREGUNTAS_IA_GENERADAS.removeAll { $0.ZONE_ID == zone.databaseID }
        
        purgePendingQueue(for: zone)
        GUARDAR_PREGUNTAS_IA_GENERADAS()
        saveState()
        reloadChallenges()
        resetZoneBackend(zone)
        
        // Force view updates for metrics
        objectWillChange.send()
    }

    private func resetZoneBackend(_ zone: ChallengeZone) {
        let payload: [String: Any] = [
            "userId": USER_ID_ACTUAL,
            "zoneId": zone.databaseID
        ]
        
        guard let url = URL(string: "\(baseURL)/gamification/resetZone") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Error on resetZoneBackend: \(error)")
            } else if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
                print("Bad status code on resetZoneBackend: \(httpResp.statusCode)")
            }
        }.resume()
    }

    private func saveState() {
        if let data = try? JSONEncoder().encode(Array(completedChallengeIDs)) {
            UserDefaults.standard.set(data, forKey: completedChallengesKey)
        }

        let xpToSave = zoneXP.reduce(into: [String: Int]()) { result, entry in
            result[entry.key.rawValue] = entry.value
        }
        if let data = try? JSONEncoder().encode(xpToSave) {
            UserDefaults.standard.set(data, forKey: zoneXPKey)
        }
    }

    private func saveUnlockedZones() {
        let rawValues = Array(unlockedZones).map(\.rawValue).sorted()
        if let data = try? JSONEncoder().encode(rawValues) {
            UserDefaults.standard.set(data, forKey: unlockedZonesKey)
        }
    }

    private func checkBadgeUnlock(zone: ChallengeZone, oldXP: Int, newXP: Int) {
        let thresholds = [
            (zone.xpGold, "oro"),
            (zone.xpSilver, "plata"),
            (zone.xpBronze, "bronce")
        ]
        
        for (threshold, level) in thresholds {
            if oldXP < threshold && newXP >= threshold {
                let zoneStr: String
                switch zone {
                case .general: zoneStr = "general"
                case .history: zoneStr = "historia"
                case .steelGallery: zoneStr = "acero"
                }
                
                let badgeName = "\(zoneStr)_\(level)"
                self.newlyUnlockedBadge = badgeName
                self.showBadgeUnlock = true
                
                var unlockedBadges = Set(UserDefaults.standard.array(forKey: unlockedBadgesKey) as? [String] ?? [])
                unlockedBadges.insert(badgeName)
                UserDefaults.standard.set(Array(unlockedBadges), forKey: unlockedBadgesKey)
                break
            }
        }
    }

    private func checkMasterBadgeUnlock(oldCount: Int, newCount: Int) {
        let total = totalChallenges
        if oldCount < total && newCount >= total {
            self.newlyUnlockedBadge = "masterdesafios"
            self.showBadgeUnlock = true
            
            var unlockedBadges = Set(UserDefaults.standard.array(forKey: unlockedBadgesKey) as? [String] ?? [])
            unlockedBadges.insert("masterdesafios")
            UserDefaults.standard.set(Array(unlockedBadges), forKey: unlockedBadgesKey)
        }
    }

    // MARK: - API & Sync
    private func sendCompletionsToBackend(challengeIDs: [String], zone: ChallengeZone, kind: ChallengeKind, totalXP: Int) {
        guard !challengeIDs.isEmpty else { return }
        let baseXP = totalXP / challengeIDs.count
        let remainder = totalXP % challengeIDs.count

        for (index, challengeID) in challengeIDs.enumerated() {
            let payload: [String: Any] = [
                "user_id": USER_ID_ACTUAL,
                "zone_id": zone.databaseID,
                "challenge_type": kind.rawValue,
                "challenge_id": challengeID,
                "xp_earned": baseXP + (index == 0 ? remainder : 0)
            ]
            sendCompletionToBackend(payload)
        }
    }

    private func sendCompletionToBackend(_ payload: [String: Any]) {
        guard let url = URL(string: "\(baseURL)/gamification/complete") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            let isError = error != nil || (response as? HTTPURLResponse)?.statusCode != 201
            if isError {
                print("⚠️ Fallo envío silencioso. Guardando en cola...")
                self?.saveToPendingQueue(payload)
            }
        }.resume()
    }
    
    private func saveToPendingQueue(_ payload: [String: Any]) {
        var queue = UserDefaults.standard.array(forKey: pendingQueueKey) as? [[String: Any]] ?? []
        queue.append(payload)
        UserDefaults.standard.set(queue, forKey: pendingQueueKey)
    }

    private func purgePendingQueue(for zone: ChallengeZone) {
        guard let queue = UserDefaults.standard.array(forKey: pendingQueueKey) as? [[String: Any]] else { return }
        let COLA_FILTRADA = queue.filter { PAYLOAD in
            guard let ZONA_PAYLOAD = PAYLOAD["zone_id"] as? Int else { return true }
            return ZONA_PAYLOAD != zone.databaseID
        }
        UserDefaults.standard.set(COLA_FILTRADA, forKey: pendingQueueKey)
    }
    
    private func processPendingQueue() {
        guard let queue = UserDefaults.standard.array(forKey: pendingQueueKey) as? [[String: Any]],
              !queue.isEmpty else { return }
        
        UserDefaults.standard.removeObject(forKey: pendingQueueKey)
        for payload in queue {
            sendCompletionToBackend(payload)
        }
    }

    private func URL_JSON_PREGUNTAS_IA() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("generated_trivia_data_user_\(USER_ID_ACTUAL).json")
    }

    private func CARGAR_PREGUNTAS_IA_GENERADAS() {
        guard let URL_ARCHIVO = URL_JSON_PREGUNTAS_IA(),
              let DATOS = try? Data(contentsOf: URL_ARCHIVO),
              let PREGUNTAS = try? JSONDecoder().decode([PREGUNTA_TRIVIA_GENERADA_LOCAL].self, from: DATOS) else {
            PREGUNTAS_IA_GENERADAS = []
            return
        }
        PREGUNTAS_IA_GENERADAS = PREGUNTAS
    }

    private func GUARDAR_PREGUNTAS_IA_GENERADAS() {
        guard let URL_ARCHIVO = URL_JSON_PREGUNTAS_IA(),
              let DATOS = try? JSONEncoder().encode(PREGUNTAS_IA_GENERADAS) else { return }
        try? DATOS.write(to: URL_ARCHIVO, options: [.atomic])
    }

    private func DESAFIO_IA_PENDIENTE(ZONA: ChallengeZone) -> ChallengeDefinition? {
        let PREGUNTAS_ZONA = PREGUNTAS_IA_GENERADAS.filter {
            $0.ZONE_ID == ZONA.databaseID && !completedChallengeIDs.contains($0.CHALLENGE_ID)
        }
        guard let QUIZ_ID = PREGUNTAS_ZONA.map(\.QUIZ_ID).sorted().first else { return nil }
        let PREGUNTAS = PREGUNTAS_ZONA
            .filter { $0.QUIZ_ID == QUIZ_ID }
            .prefix(PREGUNTAS_POR_QUIZ_IA)
            .compactMap { REGISTRO -> ChallengeQuestion? in
                guard let INDICE_CORRECTO = REGISTRO.OPTIONS.firstIndex(of: REGISTRO.CORRECT_ANSWER) else { return nil }
                return ChallengeQuestion(
                    id: REGISTRO.CHALLENGE_ID,
                    text: REGISTRO.QUESTION,
                    options: REGISTRO.OPTIONS,
                    correctIndex: INDICE_CORRECTO,
                    explanation: "Generada con Apple Intelligence usando el contexto local del Museo Horno 3."
                )
            }
        guard !PREGUNTAS.isEmpty else { return nil }
        return ChallengeDefinition(
            id: QUIZ_ID,
            zone: ZONA,
            kind: .quiz,
            title: "Trivia IA \(ZONA.rawValue.capitalized)",
            subtitle: "Desafío guardado",
            icon: ZONA.icon,
            estimatedMinutes: 5,
            xpReward: 250,
            questions: Array(PREGUNTAS)
        )
    }

    private func ENVIAR_QUIZ_GENERADO_BACKEND(PREGUNTAS: [PREGUNTA_TRIVIA_GENERADA_LOCAL]) {
        guard !PREGUNTAS.isEmpty,
              let URL_DESTINO = URL(string: "\(baseURL)/gamification/generatedQuiz"),
              let DATOS = try? JSONEncoder().encode(PREGUNTAS) else { return }

        var PETICION = URLRequest(url: URL_DESTINO)
        PETICION.httpMethod = "POST"
        PETICION.setValue("application/json", forHTTPHeaderField: "Content-Type")
        PETICION.httpBody = DATOS

        URLSession.shared.dataTask(with: PETICION) { _, RESPUESTA, ERROR in
            if let ERROR {
                print("Error enviando trivia generada: \(ERROR)")
            } else if let HTTP = RESPUESTA as? HTTPURLResponse, !(200...299).contains(HTTP.statusCode) {
                print("Bad status code on generatedQuiz: \(HTTP.statusCode)")
            }
        }.resume()
    }

    private func CARGAR_TRIVIA_IA_BACKEND() {
        for ZONA in ChallengeZone.allCases {
            guard let URL_DESTINO = URL(string: "\(baseURL)/gamification/generatedQuiz/\(USER_ID_ACTUAL)/\(ZONA.databaseID)") else { continue }
            URLSession.shared.dataTask(with: URL_DESTINO) { [weak self] DATOS, RESPUESTA, ERROR in
                guard ERROR == nil,
                      (RESPUESTA as? HTTPURLResponse)?.statusCode == 200,
                      let DATOS,
                      let PREGUNTAS = try? JSONDecoder().decode([PREGUNTA_TRIVIA_GENERADA_LOCAL].self, from: DATOS)
                else { return }

                DispatchQueue.main.async {
                    guard let SELF = self else { return }
                    var MAPA: [String: PREGUNTA_TRIVIA_GENERADA_LOCAL] = [:]
                    for PREGUNTA_LOCAL in SELF.PREGUNTAS_IA_GENERADAS {
                        MAPA[PREGUNTA_LOCAL.CHALLENGE_ID] = PREGUNTA_LOCAL
                    }
                    for PREGUNTA in PREGUNTAS {
                        MAPA[PREGUNTA.CHALLENGE_ID] = PREGUNTA
                    }
                    SELF.PREGUNTAS_IA_GENERADAS = Array(MAPA.values).sorted { $0.CHALLENGE_ID < $1.CHALLENGE_ID }
                    SELF.GUARDAR_PREGUNTAS_IA_GENERADAS()
                    SELF.objectWillChange.send()
                }
            }.resume()
        }
    }

    private func loadBackendHistory() {
        for zone in ChallengeZone.allCases {
            guard let url = URL(string: "\(baseURL)/gamification/history/\(USER_ID_ACTUAL)/\(zone.databaseID)") else { continue }
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard error == nil,
                      (response as? HTTPURLResponse)?.statusCode == 200,
                      let data,
                      let ids = try? JSONDecoder().decode([String].self, from: data)
                else { return }

                DispatchQueue.main.async {
                    guard let SELF = self else { return }
                    let IDS_VALIDOS = SELF.FILTRAR_IDS_REMOTOS_VALIDOS(ids, ZONA: zone)
                    SELF.completedChallengeIDs.formUnion(IDS_VALIDOS)
                    SELF.saveState()
                    SELF.reloadChallenges()
                    SELF.objectWillChange.send()
                }
            }.resume()
        }
    }

    private func FILTRAR_IDS_REMOTOS_VALIDOS(_ IDS: [String], ZONA: ChallengeZone) -> [String] {
        let IDS_CAMARA = Set(cameraMissions(for: ZONA).map(\.challengeID))
        let IDS_ESTATICOS = Set(allQuizQuestionsByZone[ZONA]?.map(\.id) ?? [])
        let PREFIJO_IA_ACTUAL = "\(ZONA.PREFIJO_TRIVIA_GENERADA)-IA-"

        return IDS.filter { ID in
            if IDS_CAMARA.contains(ID) { return true }
            if IDS_ESTATICOS.contains(ID) { return true }
            if ID.hasPrefix(PREFIJO_IA_ACTUAL) { return true }
            return false
        }
    }

    private func loadState() {
        if let data = UserDefaults.standard.data(forKey: completedChallengesKey),
           let ids = try? JSONDecoder().decode([String].self, from: data) {
            completedChallengeIDs = Set(ids)
        }

        if let data = UserDefaults.standard.data(forKey: unlockedZonesKey),
           let rawValues = try? JSONDecoder().decode([String].self, from: data) {
            let decodedZones = rawValues.compactMap(ChallengeZone.init(rawValue:))
            unlockedZones = Set(decodedZones).union(ChallengeCatalog.defaultUnlockedZones)
        }

        if let data = UserDefaults.standard.data(forKey: zoneXPKey),
           let rawXP = try? JSONDecoder().decode([String: Int].self, from: data) {
            zoneXP = rawXP.reduce(into: [ChallengeZone: Int]()) { result, entry in
                if let zone = ChallengeZone(rawValue: entry.key) {
                    result[zone] = entry.value
                }
            }
        }
    }

    private var availableChallengeIDs: Set<String> {
        Set(ChallengeZone.allCases.flatMap { availableChallengeIDs(for: $0) })
    }

    private func availableChallengeIDs(for zone: ChallengeZone) -> Set<String> {
        let quizIDs = Set(allQuizQuestionsByZone[zone]?.map(\.id) ?? [])
        let cameraIDs = Set(cameraMissions(for: zone).map(\.challengeID))
        return quizIDs.union(cameraIDs)
    }

    private func normalizedClassifierLabel(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: " ", with: "")
            .lowercased()
    }
}

extension ChallengeZone {
    var databaseID: Int {
        switch self {
        case .general: return 1
        case .history: return 2
        case .steelGallery: return 3
        }
    }

    var PREFIJO_TRIVIA_GENERADA: String {
        switch self {
        case .general: return "GEN"
        case .history: return "HIS"
        case .steelGallery: return "ACE"
        }
    }
}
