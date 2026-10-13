// ProfileViewModel.swift
import SwiftUI
import Combine

// MARK: - Models

struct InterestItem: Identifiable, Codable {
    let id:     Int
    let nameEs: String
    let icon:   String
    var nameTranslated: String = ""
    var displayName: String { nameTranslated.isEmpty ? nameEs : nameTranslated }
    enum CodingKeys: String, CodingKey {
        case id; case nameEs = "name_es"; case icon
    }
}

struct AvatarItem: Identifiable, Codable {
    let id:       Int
    let name:     String
    let imageUrl: String
    enum CodingKeys: String, CodingKey {
        case id; case name; case imageUrl = "image_url"
    }
}

struct Medal: Identifiable {
    let id = UUID()
    let iconKey:  String
    let nameKey:  String
    let color:    Color
    let unlocked: Bool
}

struct GamificationBadge: Identifiable {
    let id = UUID()
    let imageName: String
    let displayName: String
    let unlocked: Bool
    let isNewlyClaimed: Bool
}

// MARK: - GamificationBadge + colores para BadgeDetailView

extension GamificationBadge {
    /// Gradiente de fondo según el nivel/tipo de medalla
    var backdropColors: [Color] {
        let name = imageName.lowercased()
        if name.contains("oro") {
            return [Color(hex: "#B8860B"), Color(hex: "#FFD700"), Color(hex: "#FFA500")]
        } else if name.contains("plata") {
            return [Color(hex: "#4A4A5A"), Color(hex: "#C0C0C0"), Color(hex: "#8A8A9A")]
        } else if name.contains("bronce") {
            return [Color(hex: "#6B3A2A"), Color(hex: "#CD7F32"), Color(hex: "#8B4513")]
        } else if name.contains("master") {
            return [Color(hex: "#1A0A3A"), Color(hex: "#7B2FBE"), Color(hex: "#E040FB")]
        } else if name.contains("descargarapp") {
            return [Color(hex: "#003A6B"), Color(hex: "#0A84FF"), Color(hex: "#5AC8FA")]
        } else if name.contains("encuesta") {
            return [Color(hex: "#1A3A1A"), Color(hex: "#30D158"), Color(hex: "#34C759")]
        } else {
            return [Color(hex: "#6B2A00"), Color(hex: "#FF6B00"), Color(hex: "#FF9A5C")]
        }
    }

    var accentColor: Color { backdropColors[1] }
}

// MARK: - ProfileViewModel

final class ProfileViewModel: ObservableObject {

    // ── Datos del login ───────────────────────────────────────
    @Published var loginFullName: String = ""
    @Published var loginEmail:    String = ""

    // ── Campos del formulario ─────────────────────────────────
    @Published var firstName: String = ""
    @Published var lastName:  String = ""
    @Published var country:   String = ""
    @Published var ageRange:  Double = 25

    // ── Avatar clásico (API) ──────────────────────────────────
    @Published var selectedAvatarId:  Int?      = nil
    @Published var selectedInterests: Set<Int>  = []
    @Published var avatars:   [AvatarItem]   = []
    @Published var interests: [InterestItem] = []

    // ── Nombre confirmado ─────────────────────────────────────
    @Published var confirmedFullName: String = ""

    // ── Contraseña ────────────────────────────────────────────
    @Published var currentPassword: String  = ""
    @Published var newPassword:     String  = ""
    @Published var passwordError:   String? = nil
    @Published var passwordSuccess: Bool    = false

    // ── Estado UI ─────────────────────────────────────────────
    @Published var isSaving:      Bool    = false
    @Published var saveConfirmed: Bool    = false
    @Published var saveError:     String? = nil
    @Published var isLoading:     Bool    = false
    @Published var surveyCompleted: Bool  = UserDefaults.standard.bool(forKey: SurveyViewModel.currentUserSurveyCompletedKey)

    // ── Métricas ──────────────────────────────────────────────
    @Published var answersCount: Int = 0
    @Published var correctCount: Int = 0

    // Referencia débil al router para actualizar el avatar compartido
    weak var router: AppRouter?

    // MARK: - Derived

    var progress: Double { Double(answersCount) / 10.0 }
    var accuracy: String {
        answersCount > 0 ? "\(Int(Double(correctCount)/Double(answersCount)*100))%" : "—"
    }

    var avatarInitials: String {
        // Usa las iniciales del config si hay foto personalizada
        if let r = router, r.hasCustomPhoto, !r.photoConfig.initials.isEmpty {
            return r.photoConfig.initials.uppercased()
        }
        let parts = confirmedFullName.split(separator: " ", maxSplits: 1)
        let f = String(parts.first?.prefix(1) ?? "V").uppercased()
        let l = parts.count > 1 ? String(parts[1].prefix(1)).uppercased() : ""
        return f + l
    }

    var selectedAvatarURL: String? {
        avatars.first(where: { $0.id == selectedAvatarId })?.imageUrl
    }

    var medals: [Medal] {[
        Medal(iconKey: "trophy.fill",        nameKey: L.medalFirstStep,  color: .h3Orange,             unlocked: answersCount >= 1),
        Medal(iconKey: "star.fill",           nameKey: L.medalStreak,     color: Color(hex: "#FFD60A"), unlocked: answersCount >= 5),
        Medal(iconKey: "crown.fill",          nameKey: L.medalComplete,   color: Color(hex: "#FF9F0A"), unlocked: answersCount >= 10),
        Medal(iconKey: "checkmark.seal.fill", nameKey: L.medalPrecision,  color: Color(hex: "#30D158"), unlocked: correctCount >= 5),
        Medal(iconKey: "bolt.fill",           nameKey: L.medalPerfect,    color: Color(hex: "#0A84FF"), unlocked: correctCount >= 10),
        Medal(iconKey: "flame.fill",          nameKey: L.medalExplorer,   color: Color(hex: "#FF453A"), unlocked: answersCount >= 10 && correctCount >= 7),
    ]}

    func getGamificationBadges(newlyClaimed: String?, lm: LocalizationManager = .shared) -> [GamificationBadge] {
        var badges: [GamificationBadge] = []
        let xpData = UserDefaults.standard.data(forKey: kZoneXP)
        let rawXP = (try? JSONDecoder().decode([String: Int].self, from: xpData ?? Data())) ?? [:]
        let persistentBadges = loadUnlockedBadges()
        
        // Tupla: (clave XP, prefijo imagen, clave de localización)
        let zones: [(String, String, String, ChallengeZone)] = [
            ("general",      "general",  L.badgeZoneGeneral, .general),
            ("history",      "historia", L.badgeZoneHistory, .history),
            ("steelGallery", "acero",    L.badgeZoneSteel, .steelGallery)
        ]

        for (zoneKey, zonePrefix, zoneDisplayName, zone) in zones {
            let xp = rawXP[zoneKey] ?? 0
            let thresholds = [
                (zone.xpGold, "oro", "Oro"),
                (zone.xpSilver, "plata", "Plata"),
                (zone.xpBronze, "bronce", "Bronce")
            ]
            
            var bestLevel = "bronce"
            var isUnlocked = false
            
            for (threshold, level, _) in thresholds {
                if xp >= threshold {
                    bestLevel = level
                    isUnlocked = true
                    
                    // Retroactively save to persistent badges so they aren't lost on reset
                    let badgeName = "\(zonePrefix)_\(level)"
                    if !persistentBadges.contains(badgeName) {
                        saveUnlockedBadge(badgeName)
                    }
                    break
                }
            }
            
            // If not unlocked via current XP (XP might be 0 after reset), check persistent storage
            if !isUnlocked {
                if persistentBadges.contains("\(zonePrefix)_oro") {
                    bestLevel = "oro"
                    isUnlocked = true
                } else if persistentBadges.contains("\(zonePrefix)_plata") {
                    bestLevel = "plata"
                    isUnlocked = true
                } else if persistentBadges.contains("\(zonePrefix)_bronce") {
                    bestLevel = "bronce"
                    isUnlocked = true
                }
            }
            
            let badgeName = "\(zonePrefix)_\(bestLevel)"
            let isNewlyClaimed = (badgeName == newlyClaimed)
            badges.append(GamificationBadge(imageName: badgeName, displayName: lm.s(zoneDisplayName), unlocked: isUnlocked, isNewlyClaimed: isNewlyClaimed))
        }
        
        // --- 3 Especiales ---
        badges.append(GamificationBadge(
            imageName: "descargarapp",
            displayName: lm.s(L.badgeNamePioneer),
            unlocked: true,
            isNewlyClaimed: newlyClaimed == "descargarapp"
        ))
        
        badges.append(GamificationBadge(
            imageName: "encuesta",
            displayName: lm.s(L.badgeNameVoice),
            unlocked: surveyCompleted,
            isNewlyClaimed: newlyClaimed == "encuesta"
        ))
        
        let completedChallengesCount = UserDefaults.standard.data(forKey: kCompletedChallenges).flatMap {
            (try? JSONDecoder().decode([String].self, from: $0))?.count
        } ?? 0
        
        var isMasterUnlocked = completedChallengesCount >= 114
        if isMasterUnlocked {
            saveUnlockedBadge("masterdesafios")
        } else if persistentBadges.contains("masterdesafios") {
            isMasterUnlocked = true
        }
        
        badges.append(GamificationBadge(
            imageName: "masterdesafios",
            displayName: lm.s(L.badgeNameMaster),
            unlocked: isMasterUnlocked,
            isNewlyClaimed: newlyClaimed == "masterdesafios"
        ))
        
        return badges
    }

    private let baseURL              = Config.baseURL
    private var ID_USUARIO_ACTUAL: Int {
        UserDefaults.standard.integer(forKey: "h3_user_id")
    }
    private var kCompletedChallenges: String { "h3_completed_challenge_ids_v2_\(ID_USUARIO_ACTUAL)" }
    private var kZoneXP: String { "h3_zone_xp_v2_\(ID_USUARIO_ACTUAL)" }
    private var kUnlockedBadges: String { "h3_unlocked_badges_v2_\(ID_USUARIO_ACTUAL)" }
    private var cancellables         = Set<AnyCancellable>()
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 15
        return URLSession(configuration: c)
    }()

    init() {
        loadChallengeStats()
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.loadChallengeStats() }
            .store(in: &cancellables)
    }

    // MARK: - Aplicar configuración del editor
    // Actualiza el AppRouter para que HomeHeader se refresque automáticamente

    func applyPhotoConfig(_ config: ProfilePhotoConfig) {
        router?.applyPhotoConfig(config)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - onAppear

    func onAppear(router: AppRouter) {
        self.router       = router
        loginFullName     = router.userName
        loginEmail        = router.userEmail
        confirmedFullName = router.userName

        // Pre-rellenar iniciales del config si están vacías
        if router.photoConfig.initials.isEmpty {
            let parts = router.userName.split(separator: " ", maxSplits: 1)
            let f = String(parts.first?.prefix(1) ?? "?").uppercased()
            let l = parts.count > 1 ? String(parts[1].prefix(1)).uppercased() : ""
            router.photoConfig.initials = f + l
        }

        Task {
            await loadCatalogs()
            await loadProfile(router: router)
            await refreshSurveyCompletion()
        }
    }

    @MainActor
    func refreshSurveyCompletion() async {
        if SurveyViewModel.hasPendingSubmission() {
            await SurveyViewModel.attemptBackgroundSync()
        }
        await SurveyViewModel.refreshCompletionStatus()
        surveyCompleted = UserDefaults.standard.bool(forKey: SurveyViewModel.currentUserSurveyCompletedKey)
    }

    // MARK: - Cargar catálogos + traducir intereses

    @MainActor
    private func loadCatalogs() async {
        async let av = get("/avatars",   as: [AvatarItem].self)
        async let it = get("/interests", as: [InterestItem].self)
        avatars = (try? await av) ?? []
        let rawInterests = (try? await it) ?? []
        let lm = LocalizationManager.shared
        guard lm.needsTranslation else { interests = rawInterests; return }
        interests = rawInterests
        Task {
            var translated = rawInterests
            await withTaskGroup(of: (Int, String).self) { group in
                for (idx, item) in rawInterests.enumerated() {
                    group.addTask {
                        let result = await TranslationSessionManager.shared.translate(
                            text: item.nameEs, from: "es", to: lm.deviceLanguage)
                        return (idx, result)
                    }
                }
                for await (idx, text) in group { translated[idx].nameTranslated = text }
            }
            await MainActor.run { self.interests = translated }
        }
    }

    // MARK: - GET /profile

    @MainActor
    func loadProfile(router: AppRouter) async {
        guard let data = try? await authGet("/profile"),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { prefillFromLoginName(); return }

        let apiFirst = json["first_name"] as? String ?? ""
        let apiLast  = json["last_name"]  as? String ?? ""
        if apiFirst.isEmpty {
            prefillFromLoginName()
        } else {
            firstName = apiFirst; lastName = apiLast
            let full = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
            if !full.isEmpty { confirmedFullName = full; router.updateDisplayName(full) }
        }
        country           = json["country"]      as? String ?? ""
        if let age = json["age_range"] as? String, let v = Double(age) { ageRange = v }
        selectedAvatarId  = json["avatar_id"]    as? Int
        selectedInterests = Set((json["interest_ids"] as? [Int]) ?? [])
    }

    // MARK: - PATCH /profile

    @MainActor
    func saveProfile(router: AppRouter) async {
        isSaving = true; saveError = nil
        defer { isSaving = false }
        let body: [String: Any] = [
            "first_name":   firstName, "last_name": lastName,
            "country":      country,   "age_range": "\(Int(ageRange))",
            "avatar_id":    selectedAvatarId as Any,
            "interest_ids": Array(selectedInterests)
        ]
        do {
            try await authPatch("/profile", body: body)
            let name = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
            if !name.isEmpty { confirmedFullName = name; router.updateDisplayName(name) }
            await loadProfile(router: router)
            withAnimation(.spring(response: 0.3)) { saveConfirmed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { self.saveConfirmed = false }
            }
        } catch { saveError = "Error al guardar. Intenta de nuevo." }
    }

    // MARK: - Cambiar contraseña

    @MainActor
    func changePassword() async {
        passwordError = nil
        guard newPassword.count >= 6 else { passwordError = "Mínimo 6 caracteres"; return }
        do {
            try await authPatch("/auth/change-password",
                                body: ["current_password": currentPassword, "new_password": newPassword])
            passwordSuccess = true; currentPassword = ""; newPassword = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.passwordSuccess = false }
        } catch { passwordError = "Contraseña actual incorrecta" }
    }

    // MARK: - Eliminar cuenta

    @MainActor
    func deleteAccount(router: AppRouter) async {
        guard let token = UserDefaults.standard.string(forKey: "h3_access_token"),
              let url   = URL(string: baseURL + "/auth/account") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try? await session.data(for: req)
        clearLocalSession(); router.screen = .login
    }

    // MARK: - Logout

    func logout(router: AppRouter) { clearLocalSession(); router.screen = .login }

    private func clearLocalSession() {
        ["h3_access_token", "h3_refresh_token", "h3_name", "h3_email", "h3_user_id",
         SurveyViewModel.currentUserSurveyCompletedKey, SurveyViewModel.kPendingSubmission]
            .forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    // MARK: - Recargar badges (llamado desde ProfileView al cerrar encuesta)

    func reloadBadges() {
        surveyCompleted = UserDefaults.standard.bool(forKey: SurveyViewModel.currentUserSurveyCompletedKey)
        objectWillChange.send()
    }

    private func loadUnlockedBadges() -> Set<String> {
        Set(UserDefaults.standard.array(forKey: kUnlockedBadges) as? [String] ?? [])
    }

    private func saveUnlockedBadge(_ badgeName: String) {
        var unlocked = loadUnlockedBadges()
        guard !unlocked.contains(badgeName) else { return }
        unlocked.insert(badgeName)
        UserDefaults.standard.set(Array(unlocked), forKey: kUnlockedBadges)
    }

    func toggleInterest(_ id: Int) {
        if selectedInterests.contains(id) { selectedInterests.remove(id) }
        else if selectedInterests.count < 5 { selectedInterests.insert(id) }
    }

    // MARK: - Helpers privados

    private func prefillFromLoginName() {
        let parts = loginFullName.split(separator: " ", maxSplits: 1)
        firstName = parts.first.map(String.init) ?? ""
        lastName  = parts.count > 1 ? String(parts[1]) : ""
        confirmedFullName = loginFullName
    }

    private func loadChallengeStats() {
        if let data = UserDefaults.standard.data(forKey: kCompletedChallenges),
           let ids = try? JSONDecoder().decode([String].self, from: data) {
            answersCount = ids.count
        } else { answersCount = 0 }
        if let data = UserDefaults.standard.data(forKey: kZoneXP),
           let rawXP = try? JSONDecoder().decode([String: Int].self, from: data) {
            correctCount = min(rawXP.values.reduce(0, +) / 200, answersCount)
        } else { correctCount = 0 }
    }

    // MARK: - HTTP helpers

    private func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        let (data, _) = try await session.data(from: URL(string: baseURL + path)!)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func authGet(_ path: String) async throws -> Data {
        guard let token = UserDefaults.standard.string(forKey: "h3_access_token"),
              let url   = URL(string: baseURL + path) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await session.data(for: req)
        return data
    }

    private func authPatch(_ path: String, body: [String: Any]) async throws {
        guard let token = UserDefaults.standard.string(forKey: "h3_access_token"),
              let url   = URL(string: baseURL + path) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)",  forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
    }
}
