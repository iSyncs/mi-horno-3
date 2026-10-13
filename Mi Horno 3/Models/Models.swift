// Models.swift
import SwiftUI

// MARK: - Attraction
struct Attraction: Identifiable, Hashable {
    let id = UUID()
    let nameKey: String
    let descriptionKey: String
    let scheduleKey: String
    let icon: String
    let accentColor: Color
    let availableAllDay: Bool
    let latitude: Double
    let longitude: Double
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Attraction, rhs: Attraction) -> Bool { lhs.id == rhs.id }
}

// MARK: - Attraction Group
struct AttractionGroup: Identifiable {
    let id = UUID()
    let titleKey: String
    let subtitleKey: String
    let icon: String
    let accentColor: Color
    let gradientColors: [Color]
    let attractions: [Attraction]
}

// MARK: - Museum Catalog
enum MuseumCatalog {

    static let historyGallery = Attraction(
        nameKey: L.attrHistoryName, descriptionKey: L.attrHistoryDesc,
        scheduleKey: L.scheduleAllDay,
        icon: "clock.arrow.circlepath", accentColor: Color(hex: "#F05A28"),
        availableAllDay: true, latitude: 25.67680, longitude: -100.28960)

    static let steelGallery = Attraction(
        nameKey: L.attrSteelName, descriptionKey: L.attrSteelDesc,
        scheduleKey: L.scheduleAllDay,
        icon: "bolt.fill", accentColor: Color(hex: "#5AC8FA"),
        availableAllDay: true, latitude: 25.67640, longitude: -100.29020)

    static let paseo = Attraction(
        nameKey: L.attrPaseoName, descriptionKey: L.attrPaseoDesc,
        scheduleKey: L.scheduleClimate,
        icon: "arrow.up.to.line", accentColor: Color(hex: "#0A84FF"),
        availableAllDay: false, latitude: 25.67750, longitude: -100.28850)

    static let hornShow = Attraction(
        nameKey: L.attrShowName, descriptionKey: L.attrShowDesc,
        scheduleKey: L.scheduleAvailability,
        icon: "flame.fill", accentColor: Color(hex: "#E03010"),
        availableAllDay: false, latitude: 25.67720, longitude: -100.28900)

    static let planetTierra = Attraction(
        nameKey: L.attrPlanetName, descriptionKey: L.attrPlanetDesc,
        scheduleKey: L.scheduleAvailability,
        icon: "globe.americas.fill", accentColor: Color(hex: "#30D158"),
        availableAllDay: false, latitude: 25.67700, longitude: -100.28980)

    static let chainReaction = Attraction(
        nameKey: L.attrChainName, descriptionKey: L.attrChainDesc,
        scheduleKey: L.scheduleAvailability,
        icon: "gearshape.2.fill", accentColor: Color(hex: "#BF5AF2"),
        availableAllDay: false, latitude: 25.67660, longitude: -100.28940)

    static let groups: [AttractionGroup] = [
        AttractionGroup(
            titleKey: L.groupGalleries,
            subtitleKey: L.scheduleAllDay,
            icon: "photo.on.rectangle.angled",
            accentColor: Color(hex: "#F05A28"),
            gradientColors: [Color(hex: "#F05A28"), Color(hex: "#C03D10")],
            attractions: [historyGallery, steelGallery]
        ),
        AttractionGroup(
            titleKey: L.groupPaseo,
            subtitleKey: L.scheduleClimate,
            icon: "arrow.up.to.line",
            accentColor: Color(hex: "#0A84FF"),
            gradientColors: [Color(hex: "#0A84FF"), Color(hex: "#0040CC")],
            attractions: [paseo]
        ),
        AttractionGroup(
            titleKey: L.groupShows,
            subtitleKey: L.scheduleAvailability,
            icon: "sparkles",
            accentColor: Color(hex: "#BF5AF2"),
            gradientColors: [Color(hex: "#BF5AF2"), Color(hex: "#8944C0")],
            attractions: [hornShow, planetTierra, chainReaction]
        ),
    ]

    // Flat list para backward compat (mapa, etc.)
    static let attractions: [Attraction] = groups.flatMap { $0.attractions }
}

// MARK: - Museum schedule
enum MuseumSchedule {
    static func isOpen(at date: Date = Date()) -> Bool {
        return true //IMPORTANTE QUITARLO
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        let mins = cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
        switch weekday {
        case 2: return false
        case 3,4,5: return mins >= 660 && mins < 1080
        case 1,6,7: return mins >= 720 && mins < 1140
        default: return false
        }
    }
    static func minutesUntilNextShow(from date: Date = Date()) -> Int {
        let m = Calendar.current.component(.minute, from: date)
        return m == 0 ? 60 : 60 - m
    }
}

// MARK: - Challenge
enum ChallengeZone: String, CaseIterable, Identifiable, Codable {
    case general
    case history
    case steelGallery

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .general: return L.challengeZoneGeneral
        case .history: return L.challengeZoneHistory
        case .steelGallery: return L.challengeZoneSteelGallery
        }
    }

    var subtitleKey: String {
        switch self {
        case .general: return L.challengeZoneGeneralSubtitle
        case .history: return L.challengeZoneHistorySubtitle
        case .steelGallery: return L.challengeZoneSteelGallerySubtitle
        }
    }

    var icon: String {
        switch self {
        case .general: return "sparkles"
        case .history: return "clock.arrow.circlepath"
        case .steelGallery: return "flask.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .general: return .h3Orange
        case .history: return Color(hex: "#5AC8FA")
        case .steelGallery: return Color(hex: "#30D158")
        }
    }

    var xpBronze: Int {
        switch self {
        case .general, .steelGallery: return 1000
        case .history: return 1500
        }
    }

    var xpSilver: Int {
        switch self {
        case .general, .steelGallery: return 2000
        case .history: return 3000
        }
    }

    var xpGold: Int {
        switch self {
        case .general, .steelGallery: return 3000
        case .history: return 4500
        }
    }
}

enum ChallengeKind: String, Codable {
    case quiz
    case camera
}

struct ChallengeQuestion: Identifiable, Hashable {
    let id: String
    let text: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

struct ChallengeDefinition: Identifiable, Hashable {
    let id: String
    let zone: ChallengeZone
    let kind: ChallengeKind
    let title: String
    let subtitle: String
    let icon: String
    let estimatedMinutes: Int
    let xpReward: Int
    let questions: [ChallengeQuestion]
}

enum ChallengeCatalog {
    static let defaultUnlockedZones: Set<ChallengeZone> = [.general, .history, .steelGallery]

    static var totalCount: Int {
        challenges(lm: LocalizationManager.shared).count
    }

    static func challenges(lm: LocalizationManager) -> [ChallengeDefinition] {
        let s = lm.s

        return [
            ChallengeDefinition(
                id: "general_onboarding",
                zone: .general,
                kind: .quiz,
                title: s(L.challengeGeneralTitle),
                subtitle: s(L.challengeGeneralSubtitle),
                icon: "sparkles",
                estimatedMinutes: 3,
                xpReward: 500,
                questions: [
                    ChallengeQuestion(
                        id: "general_demo_1",
                        text: s(L.tGeneralDemo1Text),
                        options: [s(L.tGeneralDemo1Opt0), s(L.tGeneralDemo1Opt1), s(L.tGeneralDemo1Opt2), s(L.tGeneralDemo1Opt3)],
                        correctIndex: 2,
                        explanation: s(L.tGeneralDemo1Explanation)
                    ),
                    ChallengeQuestion(
                        id: "general_demo_2",
                        text: s(L.tGeneralDemo2Text),
                        options: [s(L.tGeneralDemo2Opt0), s(L.tGeneralDemo2Opt1), s(L.tGeneralDemo2Opt2), s(L.tGeneralDemo2Opt3)],
                        correctIndex: 1,
                        explanation: s(L.tGeneralDemo2Explanation)
                    ),
                    ChallengeQuestion(
                        id: "general_demo_3",
                        text: s(L.tGeneralDemo3Text),
                        options: [s(L.tGeneralDemo3Opt0), s(L.tGeneralDemo3Opt1), s(L.tGeneralDemo3Opt2), s(L.tGeneralDemo3Opt3)],
                        correctIndex: 2,
                        explanation: s(L.tGeneralDemo3Explanation)
                    ),
                    ChallengeQuestion(
                        id: "general_demo_4",
                        text: s(L.tGeneralDemo4Text),
                        options: [s(L.tGeneralDemo4Opt0), s(L.tGeneralDemo4Opt1), s(L.tGeneralDemo4Opt2), s(L.tGeneralDemo4Opt3)],
                        correctIndex: 1,
                        explanation: s(L.tGeneralDemo4Explanation)
                    ),
                    ChallengeQuestion(
                        id: "general_demo_5",
                        text: s(L.tGeneralDemo5Text),
                        options: [s(L.tGeneralDemo5Opt0), s(L.tGeneralDemo5Opt1), s(L.tGeneralDemo5Opt2), s(L.tGeneralDemo5Opt3)],
                        correctIndex: 1,
                        explanation: s(L.tGeneralDemo5Explanation)
                    )
                ]
            ),
            ChallengeDefinition(
                id: "estrella",
                zone: .general,
                kind: .camera,
                title: s(L.chalDefEstrellaTitle),
                subtitle: s(L.chalDefEstrellaSubtitle),
                icon: "star.fill",
                estimatedMinutes: 2,
                xpReward: 200,
                questions: []
            ),
            ChallengeDefinition(
                id: "history_foundry",
                zone: .history,
                kind: .quiz,
                title: s(L.challengeHistoryTitle),
                subtitle: s(L.challengeHistorySubtitle),
                icon: "clock.arrow.circlepath",
                estimatedMinutes: 4,
                xpReward: 200,
                questions: []
            ),
            ChallengeDefinition(
                id: "torpedo",
                zone: .history,
                kind: .camera,
                title: s(L.chalDefTorpedoTitle),
                subtitle: s(L.chalDefTorpedoSubtitle),
                icon: "train.side.front.car",
                estimatedMinutes: 3,
                xpReward: 300,
                questions: []
            ),
            ChallengeDefinition(
                id: "horno",
                zone: .history,
                kind: .camera,
                title: s(L.chalDefHornoTitle),
                subtitle: s(L.chalDefHornoSubtitle),
                icon: "flame.fill",
                estimatedMinutes: 3,
                xpReward: 300,
                questions: []
            ),
            ChallengeDefinition(
                id: "steel_gallery_challenges",
                zone: .steelGallery,
                kind: .quiz,
                title: s(L.challengeSteelGalleryTitle),
                subtitle: s(L.challengeSteelGallerySubtitle),
                icon: "flask.fill",
                estimatedMinutes: 4,
                xpReward: 500,
                questions: []
            ),
            ChallengeDefinition(
                id: "telefono",
                zone: .history,
                kind: .camera,
                title: s(L.chalDefTelefonoTitle),
                subtitle: s(L.chalDefTelefonoSubtitle),
                icon: "phone.fill",
                estimatedMinutes: 2,
                xpReward: 300,
                questions: []
            ),
            ChallengeDefinition(
                id: "television",
                zone: .history,
                kind: .camera,
                title: s(L.chalDefTelevisionTitle),
                subtitle: s(L.chalDefTelevisionSubtitle),
                icon: "tv",
                estimatedMinutes: 2,
                xpReward: 300,
                questions: []
            )
        ]
    }
}
