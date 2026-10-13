//
//  WrappedViewModel.swift
//  Mi Horno 3
//

import SwiftUI
import Combine

final class WrappedViewModel: ObservableObject {

    // MARK: - Published
    @Published var cards: [WrappedCard] = []
    @Published var currentIndex: Int = 0
    @Published var wrappedData: WrappedData? = nil

    // MARK: - Private
    private let answersCount: Int
    private let correctCount: Int
    private let unlockedMedals: Int
    private let totalMedals: Int
    let badges: [GamificationBadge]
    private let sessionId: String = UUID().uuidString
    private let baseURL = Config.baseURL
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 15
        return URLSession(configuration: c)
    }()

    // MARK: - Init
    init(answersCount: Int, correctCount: Int, unlockedMedals: Int, totalMedals: Int, badges: [GamificationBadge]) {
        self.answersCount   = answersCount
        self.correctCount   = correctCount
        self.unlockedMedals = unlockedMedals
        self.totalMedals    = totalMedals
        self.badges         = badges
    }

    // MARK: - Build
    /// Construye las tarjetas con traducciones. Llamar desde la View cuando lm.isReady == true.
    func buildCards(lm: LocalizationManager) {
        let nickname = VisitorNickname.generate(
            answersCount: answersCount,
            correctCount: correctCount,
            unlockedMedals: unlockedMedals,
            lm: lm
        )
        let data = WrappedData(
            answersCount: answersCount,
            correctCount: correctCount,
            unlockedMedals: unlockedMedals,
            totalMedals: totalMedals,
            nickname: nickname
        )
        wrappedData = data

        let remainingChallenges = 114 - answersCount
        let remainingMedals     = totalMedals - unlockedMedals

        cards = [
            WrappedCard(
                type: .welcome,
                title:    lm.s(L.wrappedWelcomeTitle),
                value:    lm.s(L.wrappedWelcomeValue),
                subtitle: lm.s(L.wrappedWelcomeSubtitle),
                icon: "flame.fill",
                color: Color.h3Orange, accentColor: Color.h3OrangeLight
            ),
            WrappedCard(
                type: .challenges,
                title: lm.s(L.wrappedChallengesTitle),
                value: data.progressText,
                subtitle: answersCount >= 114
                    ? lm.s(L.wrappedChallengesAllDone)
                    : String(format: lm.s(L.wrappedChallengesRemaining), remainingChallenges),
                icon: "trophy.fill",
                color: Color(hex: "#FF9F0A"), accentColor: Color(hex: "#FFD60A")
            ),
            WrappedCard(
                type: .accuracy,
                title:    lm.s(L.wrappedAccuracyTitle),
                value:    "\(data.accuracy)%",
                subtitle: accuracySubtitle(data.accuracy, lm: lm),
                icon: "checkmark.seal.fill",
                color: Color(hex: "#30D158"), accentColor: Color(hex: "#34C759")
            ),
            WrappedCard(
                type: .medals,
                title: lm.s(L.wrappedMedalsTitle),
                value: "\(unlockedMedals)/\(totalMedals)",
                subtitle: unlockedMedals == totalMedals
                    ? lm.s(L.wrappedMedalsAllDone)
                    : String(format: lm.s(L.wrappedMedalsRemaining), remainingMedals),
                icon: "medal.fill",
                color: Color(hex: "#BF5AF2"), accentColor: Color(hex: "#DA8FFF")
            ),
            WrappedCard(
                type: .nickname,
                title:    lm.s(L.wrappedNicknameTitle),
                value:    nickname.name,
                subtitle: nickname.description,
                icon:     nickname.icon,
                color: Color.h3Orange, accentColor: Color.h3OrangeLight
            ),
            WrappedCard(
                type: .closing,
                title:    lm.s(L.wrappedClosingTitle),
                value:    lm.s(L.wrappedClosingValue),
                subtitle: lm.s(L.wrappedClosingSubtitle),
                icon: "heart.fill",
                color: Color(hex: "#FF453A"), accentColor: Color(hex: "#FF6961")
            )
        ]
    }

    // MARK: - Navigation
    var isLastCard:  Bool { currentIndex >= cards.count - 1 }
    var isFirstCard: Bool { currentIndex == 0 }
    var progress:    Double { cards.isEmpty ? 0 : Double(currentIndex + 1) / Double(cards.count) }

    func next() {
        guard !isLastCard else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { currentIndex += 1 }
    }
    func previous() {
        guard !isFirstCard else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { currentIndex -= 1 }
    }
    
    // MARK: - BD: Sesión
    func startSession() {
        Task { await post("/wrapped/session/start", body: ["session_id": sessionId]) }
    }
    func endSession() {
        Task { await post("/wrapped/session/end", body: ["session_id": sessionId]) }
    }
    func registerRoom(name: String, durationSeconds: Int) {
        Task {
            await post("/wrapped/room", body: [
                "session_id":       sessionId,
                "room_name":        name,
                "duration_seconds": durationSeconds
            ])
        }
    }
    
    // MARK: - HTTP helper 
    @discardableResult
    private func post(_ path: String, body: [String: Any]) async -> Bool {
        guard let token = UserDefaults.standard.string(forKey: "h3_access_token"),
              let url   = URL(string: baseURL + path) else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json",  forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)",   forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        let success = (try? await session.data(for: req)) != nil
        return success
    }
    
    // MARK: - Helpers
    private func accuracySubtitle(_ accuracy: Int, lm: LocalizationManager) -> String {
        switch accuracy {
        case 90...100: return lm.s(L.wrappedAccuracySub90)
        case 70..<90:  return lm.s(L.wrappedAccuracySub70)
        case 50..<70:  return lm.s(L.wrappedAccuracySub50)
        case 1..<50:   return lm.s(L.wrappedAccuracySubLow)
        default:       return lm.s(L.wrappedAccuracySubZero)
        }
    }
}
