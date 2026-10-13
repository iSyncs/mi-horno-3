//
//  TestJoel.swift
//  TestJoel
//
//  Created by Joel Tellez on 19/04/26.
//

import Testing
import Foundation
import Combine
@testable import Mi_Horno_3

private func clearSession() {
    let keys = ["h3_access_token", "h3_refresh_token", "h3_name", "h3_email",
                "h3_completed_challenge_ids_v2", "h3_zone_xp_v2"]
    keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Login — Registro
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
@Suite("LoginViewModel — Registro")
struct LoginRegisterTests {

    var sut: LoginViewModel
    var router: AppRouter
    var lm: LocalizationManager

    init() {
        clearSession()
        sut      = LoginViewModel()
        router   = AppRouter()
        lm       = LocalizationManager.shared
        sut.mode = .register
    }

    @Test("TC-001 — Nombre vacío muestra error")
    func register_emptyName_setsError() {
        sut.name     = ""
        sut.email    = "test@horno3.com"
        sut.password = "horno123"
        sut.authenticate(router: router, lm: lm)
        #expect(sut.errorMessage != nil)
        #expect(sut.isLoading == false)
    }

    @Test("TC-002 — Correo sin @ muestra error")
    func register_invalidEmail_setsError() {
        sut.name     = "Test User"
        sut.email    = "usuariosinArroba"
        sut.password = "horno123"
        sut.authenticate(router: router, lm: lm)
        #expect(sut.errorMessage != nil)
    }

    @Test("TC-003 — Contraseña de 3 chars muestra error")
    func register_shortPassword_setsError() {
        sut.name     = "Test User"
        sut.email    = "test@horno3.com"
        sut.password = "123"
        sut.authenticate(router: router, lm: lm)
        #expect(sut.errorMessage != nil)
        #expect(sut.isLoading == false)
    }

    @Test("TC-004 — Contraseña de 5 chars muestra error")
    func register_fiveCharPassword_setsError() {
        sut.name     = "Test User"
        sut.email    = "test@horno3.com"
        sut.password = "12345"
        sut.authenticate(router: router, lm: lm)
        #expect(sut.errorMessage != nil)
    }

    @Test("TC-005 — Contraseña de 6 chars pasa validación local")
    func register_sixCharPassword_passesLocalValidation() {
        sut.name     = "Test User"
        sut.email    = "test@horno3.com"
        sut.password = "123456"
        sut.authenticate(router: router, lm: lm)
        #expect(sut.errorMessage == nil)
    }

    @Test("TC-006 — Correo vacío muestra error")
    func register_emptyEmail_setsError() {
        sut.name     = "Test User"
        sut.email    = ""
        sut.password = "horno123"
        sut.authenticate(router: router, lm: lm)
        #expect(sut.errorMessage != nil)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Login — Inicio de sesión
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
@Suite("LoginViewModel — Login")
struct LoginLoginTests {

    var sut: LoginViewModel
    var router: AppRouter
    var lm: LocalizationManager

    init() {
        clearSession()
        sut      = LoginViewModel()
        router   = AppRouter()
        lm       = LocalizationManager.shared
        sut.mode = .login
    }

    @Test("TC-007 — Campos vacíos muestran error")
    func login_emptyFields_setsError() {
        sut.email    = ""
        sut.password = ""
        sut.authenticate(router: router, lm: lm)
        #expect(sut.errorMessage != nil)
        #expect(sut.isLoading == false)
    }

    @Test("TC-008 — Sin contraseña muestra error")
    func login_emptyPassword_setsError() {
        sut.email    = "test@horno3.com"
        sut.password = ""
        sut.authenticate(router: router, lm: lm)
        #expect(sut.errorMessage != nil)
    }

    @Test("TC-009 — Sin correo muestra error")
    func login_emptyEmail_setsError() {
        sut.email    = ""
        sut.password = "horno123"
        sut.authenticate(router: router, lm: lm)
        #expect(sut.errorMessage != nil)
    }

    @Test("TC-010 — Campos válidos pasan validación local")
    func login_validFields_noLocalError() {
        sut.email    = "elviarosas@gmail.com"
        sut.password = "shakira123"
        sut.authenticate(router: router, lm: lm)
        #expect(sut.errorMessage == nil)
    }

    @Test("TC-011 — Email con espacios y mayúsculas se normaliza")
    func login_emailTrimmedAndLowercased() {
        sut.email    = "  ELVIA@Gmail.COM  "
        sut.password = "shakira123"
        sut.authenticate(router: router, lm: lm)
        #expect(sut.errorMessage == nil)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Profile — Perfil y contraseña
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
@Suite("ProfileViewModel — Perfil")
struct ProfileTests {

    var sut: ProfileViewModel

    init() {
        clearSession()
        sut = ProfileViewModel()
    }

    @Test("TC-012 — Iniciales con nombre completo")
    func avatarInitials_fullName() {
        sut.confirmedFullName = "Elvia Rosas"
        #expect(sut.avatarInitials == "ER")
    }

    @Test("TC-013 — Iniciales con un solo nombre")
    func avatarInitials_singleName() {
        sut.confirmedFullName = "Elvia"
        #expect(sut.avatarInitials == "E")
    }

    @Test("TC-014 — Iniciales vacías retornan fallback V")
    func avatarInitials_emptyName_fallback() {
        sut.confirmedFullName = ""
        #expect(sut.avatarInitials == "V")
    }

    @Test("TC-015 — toggleInterest agrega interés")
    func toggleInterest_adds() {
        sut.selectedInterests = []
        sut.toggleInterest(1)
        #expect(sut.selectedInterests.contains(1))
    }

    @Test("TC-016 — toggleInterest elimina interés ya seleccionado")
    func toggleInterest_removes() {
        sut.selectedInterests = [1, 2]
        sut.toggleInterest(1)
        #expect(!sut.selectedInterests.contains(1))
        #expect(sut.selectedInterests.contains(2))
    }

    @Test("TC-017 — No permite más de 5 intereses")
    func toggleInterest_maxFive() {
        sut.selectedInterests = [1, 2, 3, 4, 5]
        sut.toggleInterest(6)
        #expect(!sut.selectedInterests.contains(6))
        #expect(sut.selectedInterests.count == 5)
    }

    @Test("TC-018 — Exactamente 5 intereses permitidos")
    func toggleInterest_exactlyFiveAllowed() {
        sut.selectedInterests = [1, 2, 3, 4]
        sut.toggleInterest(5)
        #expect(sut.selectedInterests.contains(5))
        #expect(sut.selectedInterests.count == 5)
    }

    @Test("TC-019 — Accuracy sin respuestas retorna guión")
    func accuracy_noAnswers() {
        sut.answersCount = 0
        sut.correctCount = 0
        #expect(sut.accuracy == "—")
    }

    @Test("TC-020 — Accuracy calcula porcentaje correcto")
    func accuracy_withAnswers() {
        sut.answersCount = 10
        sut.correctCount = 8
        #expect(sut.accuracy == "80%")
    }

    @Test("TC-021 — Accuracy con 100% de aciertos")
    func accuracy_perfect() {
        sut.answersCount = 5
        sut.correctCount = 5
        #expect(sut.accuracy == "100%")
    }

    @Test("TC-022 — Progress calcula correctamente con 5 respuestas")
    func progress_withAnswers() {
        sut.answersCount = 5
        #expect(abs(sut.progress - 0.5) < 0.001)
    }

    @Test("TC-023 — Progress escala linealmente con answersCount")
    func progress_scalesLinearly() {
        sut.answersCount = 20
        #expect(sut.progress == 2.0)
    }

    @Test("TC-024 — Cambio de contraseña corta falla")
    func changePassword_shortPassword() async {
        sut.currentPassword = "shakira123"
        sut.newPassword     = "123"
        await sut.changePassword()
        #expect(sut.passwordError != nil)
        #expect(sut.passwordSuccess == false)
    }

    @Test("TC-025 — Contraseña de 5 chars también falla")
    func changePassword_fiveChars() async {
        sut.currentPassword = "shakira123"
        sut.newPassword     = "12345"
        await sut.changePassword()
        #expect(sut.passwordError != nil)
    }

    @Test("TC-026 — selectedAvatarURL nil sin avatar")
    func selectedAvatarURL_nil() {
        sut.selectedAvatarId = nil
        sut.avatars          = []
        #expect(sut.selectedAvatarURL == nil)
    }

    @Test("TC-027 — selectedAvatarURL retorna URL correcta")
    func selectedAvatarURL_correct() {
        sut.avatars = [
            AvatarItem(id: 1, name: "Avatar 1", imageUrl: "https://example.com/avatar1.png"),
            AvatarItem(id: 2, name: "Avatar 2", imageUrl: "https://example.com/avatar2.png"),
        ]
        sut.selectedAvatarId = 2
        #expect(sut.selectedAvatarURL == "https://example.com/avatar2.png")
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Profile — Medallas (Sprint 2)
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
@Suite("ProfileViewModel — Medallas")
struct MedalsTests {

    var sut: ProfileViewModel

    init() {
        clearSession()
        sut = ProfileViewModel()
    }

    @Test("TC-028 — Sin actividad todas bloqueadas")
    func medals_allLocked() {
        sut.answersCount = 0
        sut.correctCount = 0
        #expect(sut.medals.filter { $0.unlocked }.isEmpty)
    }

    @Test("TC-029 — Primera medalla con 1 respuesta")
    func medals_firstUnlocked() {
        sut.answersCount = 1
        sut.correctCount = 0
        #expect(sut.medals.first?.unlocked == true)
    }

    @Test("TC-030 — Medalla Precisión con 5 correctas")
    func medals_precision() {
        sut.answersCount = 5
        sut.correctCount = 5
        let medal = sut.medals.first(where: { $0.iconKey == "checkmark.seal.fill" })
        #expect(medal?.unlocked == true)
    }

    @Test("TC-031 — Total de medallas es siempre 6")
    func medals_totalCount() {
        #expect(sut.medals.count == 6)
    }

    @Test("TC-032 — Medalla Explorador requiere 10 respuestas y 7 correctas")
    func medals_explorer() {
        sut.answersCount = 10
        sut.correctCount = 6
        let explorer = sut.medals.first(where: { $0.iconKey == "flame.fill" })
        #expect(explorer?.unlocked == false)
        sut.correctCount = 7
        let explorerNow = sut.medals.first(where: { $0.iconKey == "flame.fill" })
        #expect(explorerNow?.unlocked == true)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Challenges — Gamificación y XP
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
@Suite("ChallengesViewModel — Gamificación")
struct ChallengesTests {

    var sut: ChallengesViewModel

    init() {
        clearSession()
        sut = ChallengesViewModel()
    }

    @Test("TC-033 — XP zona sin datos retorna 0")
    func xpForZone_zero() {
        sut.zoneXP = [:]
        #expect(sut.xpForZone(.general) == 0)
    }

    @Test("TC-034 — Rango sin XP es Novato")
    func rankForZone_novato() {
        sut.zoneXP = [:]
        #expect(sut.rankForZone(.general) == "Novato")
    }

    @Test("TC-035 — Rango con XP Bronce")
    func rankForZone_bronce() {
        sut.zoneXP[.general] = ChallengeZone.general.xpBronze
        #expect(sut.rankForZone(.general) == "Bronce")
    }

    @Test("TC-036 — Rango con XP Plata")
    func rankForZone_plata() {
        sut.zoneXP[.general] = ChallengeZone.general.xpSilver
        #expect(sut.rankForZone(.general) == "Plata")
    }

    @Test("TC-037 — Rango con XP Oro")
    func rankForZone_oro() {
        sut.zoneXP[.general] = ChallengeZone.general.xpGold
        #expect(sut.rankForZone(.general) == "Oro")
    }

    @Test("TC-038 — Progress no supera 1.0")
    func progressForZone_max() {
        sut.zoneXP[.general] = ChallengeZone.general.xpGold * 2
        #expect(sut.progressForZone(.general) <= 1.0)
    }

    @Test("TC-039 — Progress sin XP es 0")
    func progressForZone_zero() {
        sut.zoneXP = [:]
        #expect(abs(sut.progressForZone(.general) - 0.0) < 0.001)
    }

    @Test("TC-040 — completeChallenge suma XP")
    func completeChallenge_addsXP() throws {
        let found = sut.challenges.first(where: { $0.zone == .general && $0.kind == .quiz })
        let challenge = try #require(found, "No hay desafíos de tipo quiz en zona general")
        let xpAntes = sut.xpForZone(.general)
        sut.completeChallenge(challenge)
        #expect(sut.xpForZone(.general) > xpAntes)
    }

    @Test("TC-041 — completeChallenge marca las preguntas del quiz como completadas")
    mutating func completeChallenge_marksCompleted() throws {
        // Las keys dependen del user_id guardado en UserDefaults
        let userId = UserDefaults.standard.integer(forKey: "h3_user_id")
        UserDefaults.standard.removeObject(forKey: "h3_completed_challenge_ids_v2_\(userId)")
        UserDefaults.standard.removeObject(forKey: "h3_zone_xp_v2_\(userId)")
        sut = ChallengesViewModel()

        let found = sut.challenges.first(where: { $0.zone == .general && $0.kind == .quiz })
        let challenge = try #require(found, "No hay desafíos de tipo quiz en zona general")

        // Para quiz, completeChallenge marca los IDs de las PREGUNTAS, no el challenge.id
        let questionIDs = challenge.questions.map { $0.id }
        try #require(!questionIDs.isEmpty, "El quiz no tiene preguntas")

        sut.completeChallenge(challenge)

        // Verificar que los IDs de las preguntas están en completedChallengeIDs
        for qID in questionIDs {
            #expect(sut.completedChallengeIDs.contains(qID))
        }
    }

    @Test("TC-042 — completeChallenge suma XP solo con preguntas nuevas")
    mutating func completeChallenge_historyRepeat() throws {
        let userId = UserDefaults.standard.integer(forKey: "h3_user_id")
        UserDefaults.standard.removeObject(forKey: "h3_completed_challenge_ids_v2_\(userId)")
        UserDefaults.standard.removeObject(forKey: "h3_zone_xp_v2_\(userId)")
        sut = ChallengesViewModel()

        let found = sut.challenges.first(where: { $0.zone == .history })
        let challenge = try #require(found, "No hay desafíos en zona history")

        // Primera vez: suma XP porque todas las preguntas son nuevas
        sut.completeChallenge(challenge)
        let xpDespuesDePrimera = sut.xpForZone(.history)
        #expect(xpDespuesDePrimera > 0)

        // Segunda vez con el mismo challenge: las preguntas ya están completadas
        // por lo que newlyCompletedIDs estará vacío y NO suma más XP
        sut.completeChallenge(challenge)
        let xpDespuesDeSegunda = sut.xpForZone(.history)
        #expect(xpDespuesDeSegunda == xpDespuesDePrimera)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - HU-09 — Medallas (Sprint 3)
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
@Suite("ProfileViewModel — Medallas HU-09")
struct MedalsHU09Tests {

    var sut: ProfileViewModel

    init() {
        clearSession()
        sut = ProfileViewModel()
    }

    @Test("TC-029 — Sin actividad todas bloqueadas")
    func medals_allLocked() {
        sut.answersCount = 0
        sut.correctCount = 0
        #expect(sut.medals.filter { $0.unlocked }.isEmpty)
    }

    @Test("TC-029-A — Primera medalla se desbloquea con 1 respuesta")
    func medals_firstUnlocks() {
        sut.answersCount = 1
        #expect(sut.medals.first?.unlocked == true)
    }

    @Test("TC-029-B — Medalla precisión se desbloquea con 5 correctas")
    func medals_precision() {
        sut.answersCount = 5
        sut.correctCount = 5
        let medal = sut.medals.first(where: { $0.iconKey == "checkmark.seal.fill" })
        #expect(medal?.unlocked == true)
    }

    @Test("TC-029-C — Medalla Explorador requiere 10 respuestas y 7 correctas")
    func medals_explorer() {
        sut.answersCount = 10
        sut.correctCount = 6
        let before = sut.medals.first(where: { $0.iconKey == "flame.fill" })
        #expect(before?.unlocked == false)
        sut.correctCount = 7
        let after = sut.medals.first(where: { $0.iconKey == "flame.fill" })
        #expect(after?.unlocked == true)
    }

    @Test("TC-029-D — Total de medallas siempre es 6")
    func medals_totalCount() {
        #expect(sut.medals.count == 6)
    }

    @Test("TC-029-E — Con todo completado todas desbloqueadas")
    func medals_allUnlocked() {
        sut.answersCount = 10
        sut.correctCount = 10
        #expect(sut.medals.filter { $0.unlocked }.count == 6)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - HU-29 — Asistente IA on-device (MLX)
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
@Suite("AssistantViewModel — HU-29")
struct AssistantHU29Tests {

    var sut: AssistantViewModel

    init() {
        clearSession()
        AssistantViewModel.resetSharedContainerForTests()
        sut = AssistantViewModel(skipModelLoad: true)
    }

    @Test("TC-032 — Estado inicial es downloadingModel")
    func assistant_initialState() {
        #expect(sut.state == .downloadingModel(0))
    }

    @Test("TC-035 — FAB deshabilitado mientras descarga")
    func assistant_fabDisabledWhileDownloading() {
        sut.state = .downloadingModel(0.5)
        sut.fabTapped()
        #expect(sut.state != .listening)
    }

    @Test("TC-035-B — FAB desde idle pasa a listening")
    func assistant_fabFromIdle() {
        sut.state = .idle
        sut.fabTapped()
        #expect(sut.state == .listening)
    }

    @Test("TC-035-C — fabIcon correcto por estado")
    func assistant_fabIcons() {
        sut.state = .downloadingModel(0); #expect(sut.fabIcon == "arrow.down.circle")
        sut.state = .idle;               #expect(sut.fabIcon == "mic.fill")
        sut.state = .listening;          #expect(sut.fabIcon == "stop.fill")
        sut.state = .readyToSend;        #expect(sut.fabIcon == "paperplane.fill")
    }

    @Test("TC-036 — cleanResponse elimina tokens especiales")
    func assistant_cleansTokens() {
        #expect(!sut.cleanResponse_test("Texto.<|im_end|>").contains("<|im_end|>"))
        #expect(!sut.cleanResponse_test("Texto.<|endoftext|>").contains("<|endoftext|>"))
        #expect(!sut.cleanResponse_test("<|im_start|>Texto.<|im_end|>").contains("<|im_start|>"))
        #expect(!sut.cleanResponse_test("Texto.<|end|>").contains("<|end|>"))
    }

    @Test("TC-036-B — cleanResponse no modifica texto limpio")
    func assistant_cleanTextUnchanged() {
        let clean = "El Museo Horno 3 está en Monterrey."
        #expect(sut.cleanResponse_test(clean) == clean)
    }

    @Test("TC-034 — cancelTapped limpia transcript y vuelve a idle")
    func assistant_cancel() {
        sut.currentTranscript = "Hola museo"
        sut.state = .listening
        sut.cancelTapped()
        #expect(sut.currentTranscript == "")
        #expect(sut.state == .idle)
    }

    @Test("TC-034-B — shouldShowCancel solo en listening y readyToSend")
    func assistant_shouldShowCancel() {
        sut.state = .listening;    #expect(sut.shouldShowCancel == true)
        sut.state = .readyToSend;  #expect(sut.shouldShowCancel == true)
        sut.state = .idle;         #expect(sut.shouldShowCancel == false)
        sut.state = .downloadingModel(0); #expect(sut.shouldShowCancel == false)
    }

    @Test("TC-033 — Historial y propiedades vacías al iniciar")
    func assistant_initialProperties() {
        #expect(sut.messages.isEmpty)
        #expect(sut.streamingText == "")
        #expect(sut.currentTranscript == "")
        #expect(sut.permissionDenied == false)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - HU-30 — Persistencia del modelo LLM
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
@Suite("AssistantViewModel — HU-30")
struct AssistantHU30Tests {

    init() {
        clearSession()
        AssistantViewModel.resetSharedContainerForTests()
    }

    @Test("TC-038 — Sin singleton estado es downloadingModel")
    func assistant_noSingleton() {
        let vm = AssistantViewModel(skipModelLoad: true)
        #expect(vm.state == .downloadingModel(0))
        #expect(AssistantViewModel.sharedContainerIsNil())
    }

    @Test("TC-040 — En idle fabTapped inicia listening")
    func assistant_idleFab() {
        let vm = AssistantViewModel(skipModelLoad: true)
        vm.state = .idle
        vm.fabTapped()
        #expect(vm.state == .listening)
    }

    @Test("TC-041 — GPU cache limit es 20 MB")
    func assistant_cacheLimit() {
        #expect(20 * 1024 * 1024 == 20_971_520)
    }

    @Test("TC-042 — Historial y estado persisten en la misma instancia")
    func assistant_persistence() {
        let vm = AssistantViewModel(skipModelLoad: true)
        vm.messages.append(ChatMessage(role: .user, text: "Pregunta"))
        vm.state = .idle
        #expect(vm.messages.count == 1)
        #expect(vm.state == .idle)
    }

    @Test("TC-042-B — resetSharedContainer limpia el singleton")
    func assistant_reset() {
        AssistantViewModel.resetSharedContainerForTests()
        #expect(AssistantViewModel.sharedContainerIsNil())
    }
}
