// SurveyViewModel.swift
import SwiftUI
import Combine

@MainActor
final class SurveyViewModel: ObservableObject {

    // MARK: - UserDefaults keys (static para acceso desde ProfileViewModel)
    static let kSurveyCompleted   = "h3_survey_completed"
    static let kPendingSubmission = "h3_survey_pending_submission"
    static let kUnlockedBadges    = "h3_unlocked_badges_v2"

    static var currentUserUnlockedBadgesKey: String {
        let userId = UserDefaults.standard.integer(forKey: "h3_user_id")
        return "\(kUnlockedBadges)_\(userId)"
    }

    static var currentUserSurveyCompletedKey: String {
        let userId = UserDefaults.standard.integer(forKey: "h3_user_id")
        return "\(kSurveyCompleted)_\(userId)"
    }

    // MARK: - Preguntas (hardcoded por compatibilidad offline)
    let questions: [SurveyQuestion] = [
        SurveyQuestion(id: 0,
            text: "¿Cómo calificarías tu experiencia general en el museo hoy?",
            options: ["Excelente", "Buena", "Regular", "Mala"],
            hasFollowUp: false),
        SurveyQuestion(id: 1,
            text: "¿Qué tan útil te pareció la aplicación para recorrer las salas?",
            options: ["Muy útil", "Útil", "Poco útil", "No la necesité"],
            hasFollowUp: false),
        SurveyQuestion(id: 2,
            text: "¿Qué mejorarías de la app?",
            options: ["Desafíos", "Accesibilidad", "Mapa", "Perfil"],
            hasFollowUp: true),
        SurveyQuestion(id: 3,
            text: "¿Cuánto tiempo duró tu visita aproximadamente?",
            options: ["Menos de 30 min", "De 30 a 60 min", "De 1 a 2 horas", "Más de 2 horas"],
            hasFollowUp: false),
        SurveyQuestion(id: 4,
            text: "¿Qué tan probable es que recomiendes este museo a un amigo?",
            options: ["Muy probable", "Probable", "Poco probable", "Nada probable"],
            hasFollowUp: false),
        SurveyQuestion(id: 5,
            text: "¿Qué tan probable es que vuelvas a visitarnos?",
            options: ["Muy probable", "Probable", "Poco probable", "Nada probable"],
            hasFollowUp: false),
    ]

    @Published var currentIndex: Int = 0
    @Published var answers: [Int: String] = [:]
    @Published var followUpTexts: [Int: String] = [:]
    @Published var submitted: Bool = false

    var current: SurveyQuestion { questions[currentIndex] }
    var isLast: Bool { currentIndex == questions.count - 1 }
    var selectedOption: String? { answers[current.id] }
    var progress: Double { Double(answers.count) / Double(questions.count) }

    // MARK: - Navegación

    func select(_ option: String) {
        answers[current.id] = option
        if !current.hasFollowUp && !isLast {
            Task {
                try? await Task.sleep(nanoseconds: 320_000_000)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                    self.currentIndex += 1
                }
            }
        }
    }

    func next() {
        guard currentIndex < questions.count - 1 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
            currentIndex += 1
        }
    }

    // MARK: - Submit (offline-first)

    func submit() {
        let payload = buildPayload()

        // 1. Guardar localmente como pendiente (fallback de red)
        savePendingSubmission(payload)

        // 2. Marcar badge y encuesta como completados de inmediato
        Self.markSurveyCompletedLocally()

        // 3. Mostrar éxito sin esperar red
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            submitted = true
        }

        // 4. Intentar sincronizar en background (silencioso)
        Task { await Self.attemptBackgroundSync() }
    }

    // MARK: - Background sync (static — puede llamarse desde cualquier punto de la app)

    /// Intenta enviar la encuesta pendiente al backend.
    /// Silencioso: nunca lanza errores ni actualiza UI.
    /// Elimina el pendiente solo si el servidor confirma (201) o ya lo tenía (409).
    static func attemptBackgroundSync() async {
        guard
            let data  = UserDefaults.standard.data(forKey: kPendingSubmission),
            let token = UserDefaults.standard.string(forKey: "h3_access_token"),
            let url   = URL(string: Config.baseURL + "/survey/submit")
        else { return }

        var req = URLRequest(url: url)
        req.httpMethod  = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)",  forHTTPHeaderField: "Authorization")
        req.httpBody    = data
        req.timeoutInterval = 15

        guard let (_, response) = try? await URLSession.shared.data(for: req),
              let http = response as? HTTPURLResponse else { return }

        switch http.statusCode {
        case 201, 409:
            // 201 → guardado correctamente
            // 409 → ya existía en el servidor (envío previo exitoso)
            // En ambos casos la respuesta está persistida: limpiar pendiente local
            UserDefaults.standard.removeObject(forKey: kPendingSubmission)
            markSurveyCompletedLocally()
        default:
            break
        }
    }

    @discardableResult
    static func refreshCompletionStatus() async -> Bool? {
        guard
            let token = UserDefaults.standard.string(forKey: "h3_access_token"),
            let url = URL(string: Config.baseURL + "/survey/status")
        else { return nil }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 15

        guard let (data, response) = try? await URLSession.shared.data(for: req),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200,
              let status = try? JSONDecoder().decode(SurveyStatusResponse.self, from: data)
        else { return nil }

        if status.completed {
            markSurveyCompletedLocally()
        } else if !hasPendingSubmission() {
            UserDefaults.standard.set(false, forKey: currentUserSurveyCompletedKey)
        }

        return status.completed
    }

    static func hasPendingSubmission() -> Bool {
        UserDefaults.standard.data(forKey: kPendingSubmission) != nil
    }

    static func markSurveyCompletedLocally() {
        var unlocked = Set(UserDefaults.standard.array(forKey: currentUserUnlockedBadgesKey) as? [String] ?? [])
        unlocked.insert("encuesta")
        UserDefaults.standard.set(Array(unlocked), forKey: currentUserUnlockedBadgesKey)
        UserDefaults.standard.set(true, forKey: currentUserSurveyCompletedKey)
    }

    // MARK: - Privados

    private func buildPayload() -> SurveySubmissionPayload {
        let items = questions.map { q in
            SurveyResponseItem(
                questionId: q.id,
                questionText: q.text,
                selectedOption: answers[q.id] ?? "",
                followUpText: followUpTexts[q.id].flatMap { $0.isEmpty ? nil : $0 }
            )
        }
        return SurveySubmissionPayload(
            responses: items,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
    }

    private func savePendingSubmission(_ payload: SurveySubmissionPayload) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: Self.kPendingSubmission)
    }
}
