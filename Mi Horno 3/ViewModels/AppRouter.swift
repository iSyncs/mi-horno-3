// AppRouter.swift
import SwiftUI
import Combine

enum AppScreen: Equatable { case splash, login, main }

enum MainTab: String, CaseIterable, Identifiable {
    case home        = "house.fill"
    case challenges  = "trophy.fill"
    case map         = "map.fill"
    case translation = "translate"
    case profile     = "person.fill"
    var id: String { rawValue }

    func label(lm: LocalizationManager) -> String {
        switch self {
        case .home:        return lm.s(L.tabHome)
        case .challenges:  return lm.s(L.tabChallenges)
        case .map:         return lm.s(L.tabMap)
        case .translation: return lm.s(L.tabTranslation)
        case .profile:     return lm.s(L.tabProfile)
        }
    }
}

struct IndoorMapAssistanceContext {
    var currentNodeID: Int?
    var currentNodeName: String?
    var floorCode: String?
    var qrCode: String?
    var x: Double?
    var y: Double?
    var selectedDestinationName: String?
    var selectedRouteName: String?

    static let empty = IndoorMapAssistanceContext()
}

final class AppRouter: ObservableObject {
    @Published var screen:    AppScreen = .splash
    @Published var activeTab: MainTab   = .home
    @Published var userName:  String    = ""
    @Published var userEmail: String    = ""
    @Published var userId:    Int       = 0

    // ── Foto de perfil personalizada — compartida entre ProfileView y HomeHeader ──
    @Published var photoConfig:   ProfilePhotoConfig = ProfilePhotoConfig()
    @Published var hasCustomPhoto: Bool              = false
    @Published var newlyClaimedBadge: String? = nil
    @Published var indoorMapContext: IndoorMapAssistanceContext = .empty

    private let kName        = "h3_name"
    private let kEmail       = "h3_email"
    private let kUserId      = "h3_user_id"
    private let kPhotoConfig = "h3_photo_config_v1"

    init() {
        userName  = UserDefaults.standard.string(forKey: kName)  ?? ""
        userEmail = UserDefaults.standard.string(forKey: kEmail) ?? ""
        userId    = UserDefaults.standard.integer(forKey: kUserId)
        loadSavedPhotoConfig()
    }

    func login(id: Int, name: String, email: String) {
        userId    = id
        userName  = name
        userEmail = email
        UserDefaults.standard.set(id,    forKey: kUserId)
        UserDefaults.standard.set(name,  forKey: kName)
        UserDefaults.standard.set(email, forKey: kEmail)
        withAnimation(.easeInOut(duration: 0.45)) { screen = .main }
    }

    func login(name: String, email: String) {
        login(id: UserDefaults.standard.integer(forKey: kUserId), name: name, email: email)
    }

    func updateDisplayName(_ fullName: String) {
        guard !fullName.isEmpty else { return }
        userName = fullName
        UserDefaults.standard.set(fullName, forKey: kName)
    }

    func navigateTo(_ tab: MainTab) {
        activeTab = tab
    }

    func updateIndoorMapContext(_ context: IndoorMapAssistanceContext) {
        indoorMapContext = context
    }

    // MARK: - Actualizar foto de perfil (llamado desde ProfileViewModel)

    func applyPhotoConfig(_ config: ProfilePhotoConfig) {
        self.photoConfig    = config
        self.hasCustomPhoto = true
        savePhotoConfig(config)
    }

    // MARK: - Persistencia de metadatos (sin UIImage)

    private func savePhotoConfig(_ config: ProfilePhotoConfig) {
        var dict: [String: Any] = [
            "mode":         config.mode.rawValue,
            "initials":     config.initials,
            "fontStyle":    config.fontStyle,
            "frameStyle":   config.frame.rawValue,
            "frameOpacity": config.frameOpacity,
            "shapeStyle":   config.shape.rawValue,
        ]
        switch config.background {
        case .gradient(let i):   dict["bgType"] = "gradient"; dict["bgIndex"] = i
        case .solidColor(let i): dict["bgType"] = "solid";    dict["bgIndex"] = i
        }
        UserDefaults.standard.set(dict, forKey: kPhotoConfig)
    }

    private func loadSavedPhotoConfig() {
        guard let dict = UserDefaults.standard.dictionary(forKey: kPhotoConfig) else { return }
        var config = ProfilePhotoConfig()
        if let raw = dict["mode"] as? String, let m = AvatarMode(rawValue: raw) { config.mode = m }
        config.initials     = dict["initials"]     as? String ?? ""
        config.fontStyle    = dict["fontStyle"]    as? Int    ?? 0
        config.frameOpacity = dict["frameOpacity"] as? Double ?? 1.0
        if let raw = dict["frameStyle"] as? String, let f = AvatarFrame(rawValue: raw) { config.frame = f }
        if let raw = dict["shapeStyle"] as? String, let s = AvatarShape(rawValue: raw) { config.shape = s }
        let bgType  = dict["bgType"]  as? String ?? "gradient"
        let bgIndex = dict["bgIndex"] as? Int    ?? 0
        config.background = bgType == "solid" ? .solidColor(bgIndex) : .gradient(bgIndex)
        // La foto UIImage no persiste — solo metadatos
        if config.mode == .photo { config.mode = .initials }
        self.photoConfig    = config
        self.hasCustomPhoto = true
    }
}
