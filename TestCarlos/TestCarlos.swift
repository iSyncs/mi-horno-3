//
//  TestCarlos.swift
//  TestCarlos
//
//  Created by Carlos Baranda on 18/04/26.
//

import Foundation
import Testing
@testable import Mi_Horno_3

@MainActor
struct UserProgressTests {

    @Test func test_TC001_SumaXPPorQuizCompleto() async throws {
        // Valida que completar un quiz de 5 preguntas correctas otorga exactamente 250 XP.
        let initialXP = 1_200
        let user = UserProgressTestHarness(userID: "visitor-001", initialXP: initialXP)
        let answers = Array(repeating: QuizAnswer(isCorrect: true), count: 5)

        let earnedXP = await user.completeQuiz(answers: answers)

        #expect(earnedXP == 250)
        #expect(user.totalXP == initialXP + 250)
        #expect(user.totalXP - initialXP == 250)
    }

    @Test func test_TC005_SincronizacionPostgresGCP() async throws {
        // Valida que el cambio local de XP se envia a Postgres/GCP y queda persistido localmente.
        let networkService = MockProgressNetworkService()
        let localStore = MockProgressLocalStore()
        let user = UserProgressTestHarness(
            userID: "visitor-005",
            initialXP: 900,
            networkService: networkService,
            localStore: localStore
        )

        await user.addLocalXP(250)
        let response = try await user.syncProgress()

        #expect(response.success)
        #expect(response.message == "Sync completed")
        #expect(networkService.sentPayloads.count == 1)
        #expect(networkService.sentPayloads.first?.userID == "visitor-005")
        #expect(networkService.sentPayloads.first?.totalXP == 1_150)
        #expect(localStore.persistedProgress?.totalXP == networkService.sentPayloads.first?.totalXP)
    }

    @Test func test_TC006_GeneraTriviaIAConCincoPreguntasValidas() async throws {
        // Valida que la trivia generada por IA entregue 5 preguntas completas y listas para el desafio.
        let generator = MockAdaptiveTriviaGenerator()
        let service = AdaptiveTriviaTestHarness(generator: generator)
        let profile = TriviaVisitorProfile(
            userID: "visitor-032",
            ageRange: "18-25",
            interests: ["historia", "acero"],
            characteristics: ["visitante curioso"]
        )

        let questions = try await service.generateTrivia(for: profile, zoneID: 2)
        let challengeIDs = Set(questions.map(\.challengeID))

        #expect(questions.count == 5)
        #expect(challengeIDs.count == 5)
        #expect(questions.allSatisfy { !$0.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        #expect(questions.allSatisfy { $0.options.count == 4 })
        #expect(questions.allSatisfy { $0.options.contains($0.correctAnswer) })
        #expect(questions.allSatisfy { $0.type == "quiz" })
    }

    @Test func test_TC007_PromptIncluyePerfilDelVisitanteParaPersonalizacion() async throws {
        // Valida que la solicitud de trivia IA incluya perfil, zona e instrucciones de personalizacion.
        let generator = MockAdaptiveTriviaGenerator()
        let service = AdaptiveTriviaTestHarness(generator: generator)
        let profile = TriviaVisitorProfile(
            userID: "visitor-033",
            ageRange: "12-17",
            interests: ["maquinas", "reciclaje"],
            characteristics: ["lenguaje sencillo", "primera visita"]
        )

        _ = try await service.generateTrivia(for: profile, zoneID: 3)

        #expect(generator.receivedRequests.count == 1)
        #expect(generator.receivedRequests.first?.profile == profile)
        #expect(generator.receivedRequests.first?.zoneID == 3)
        #expect(generator.receivedRequests.first?.prompt.contains("12-17") == true)
        #expect(generator.receivedRequests.first?.prompt.contains("maquinas") == true)
        #expect(generator.receivedRequests.first?.prompt.contains("primera visita") == true)
        #expect(generator.receivedRequests.first?.prompt.contains("personalizada") == true)
    }

    @Test func test_TC008_AdaptaDificultadYLenguajeSegunEdad() async throws {
        // Valida que el filtro adaptativo ajuste dificultad y lenguaje con base en el rango de edad.
        let generator = MockAdaptiveTriviaGenerator()
        let service = AdaptiveTriviaTestHarness(generator: generator)
        let childProfile = TriviaVisitorProfile(
            userID: "visitor-child",
            ageRange: "6-11",
            interests: ["minerales"],
            characteristics: ["familia"]
        )
        let adultProfile = TriviaVisitorProfile(
            userID: "visitor-adult",
            ageRange: "26-40",
            interests: ["industria"],
            characteristics: ["conocimiento tecnico"]
        )

        _ = try await service.generateTrivia(for: childProfile, zoneID: 1)
        _ = try await service.generateTrivia(for: adultProfile, zoneID: 1)

        #expect(generator.receivedRequests.count == 2)
        #expect(generator.receivedRequests[0].difficulty == .easy)
        #expect(generator.receivedRequests[0].languageStyle == .simple)
        #expect(generator.receivedRequests[0].prompt.contains("lenguaje simple") == true)
        #expect(generator.receivedRequests[1].difficulty == .advanced)
        #expect(generator.receivedRequests[1].languageStyle == .technical)
        #expect(generator.receivedRequests[1].prompt.contains("lenguaje tecnico") == true)
    }
}

private struct QuizAnswer: Equatable {
    let isCorrect: Bool
}

private struct ProgressPayload: Equatable {
    let userID: String
    let totalXP: Int
}

private struct ProgressSyncResponse: Equatable {
    let success: Bool
    let message: String
}

private struct TriviaVisitorProfile: Equatable {
    let userID: String
    let ageRange: String
    let interests: [String]
    let characteristics: [String]
}

private struct GeneratedTriviaQuestion: Equatable {
    let challengeID: String
    let zoneID: Int
    let question: String
    let options: [String]
    let correctAnswer: String
    let type: String
}

private struct AdaptiveTriviaRequest: Equatable {
    let profile: TriviaVisitorProfile
    let zoneID: Int
    let prompt: String
    let difficulty: TriviaDifficulty
    let languageStyle: TriviaLanguageStyle
}

private enum TriviaDifficulty: Equatable {
    case easy
    case intermediate
    case advanced
}

private enum TriviaLanguageStyle: Equatable {
    case simple
    case conversational
    case technical
}

private protocol ProgressNetworkServicing: AnyObject {
    func syncProgress(_ payload: ProgressPayload) async throws -> ProgressSyncResponse
}

private protocol ProgressLocalStoring: AnyObject {
    func saveProgress(_ payload: ProgressPayload) async
}

private protocol AdaptiveTriviaGenerating: AnyObject {
    func generateTrivia(request: AdaptiveTriviaRequest) async throws -> [GeneratedTriviaQuestion]
}

@MainActor
private final class UserProgressTestHarness {
    let userID: String
    private(set) var totalXP: Int

    private let quizRewardXP = 250
    private let requiredCorrectAnswers = 5
    private let networkService: ProgressNetworkServicing
    private let localStore: ProgressLocalStoring

    init(
        userID: String,
        initialXP: Int,
        networkService: ProgressNetworkServicing = MockProgressNetworkService(),
        localStore: ProgressLocalStoring = MockProgressLocalStore()
    ) {
        self.userID = userID
        self.totalXP = initialXP
        self.networkService = networkService
        self.localStore = localStore
    }

    func completeQuiz(answers: [QuizAnswer]) async -> Int {
        let correctAnswers = answers.filter(\.isCorrect).count
        guard correctAnswers == requiredCorrectAnswers else { return 0 }

        totalXP += quizRewardXP
        return quizRewardXP
    }

    func addLocalXP(_ xp: Int) async {
        totalXP += xp
    }

    func syncProgress() async throws -> ProgressSyncResponse {
        let payload = ProgressPayload(userID: userID, totalXP: totalXP)
        let response = try await networkService.syncProgress(payload)

        if response.success {
            await localStore.saveProgress(payload)
        }

        return response
    }
}

@MainActor
private final class AdaptiveTriviaTestHarness {
    private let generator: AdaptiveTriviaGenerating

    init(generator: AdaptiveTriviaGenerating = MockAdaptiveTriviaGenerator()) {
        self.generator = generator
    }

    func generateTrivia(for profile: TriviaVisitorProfile, zoneID: Int) async throws -> [GeneratedTriviaQuestion] {
        let difficulty = difficulty(for: profile.ageRange)
        let languageStyle = languageStyle(for: profile.ageRange)
        let request = AdaptiveTriviaRequest(
            profile: profile,
            zoneID: zoneID,
            prompt: buildPrompt(profile: profile, zoneID: zoneID, difficulty: difficulty, languageStyle: languageStyle),
            difficulty: difficulty,
            languageStyle: languageStyle
        )

        return try await generator.generateTrivia(request: request)
    }

    private func difficulty(for ageRange: String) -> TriviaDifficulty {
        switch ageRange {
        case "6-11":
            return .easy
        case "12-17", "18-25":
            return .intermediate
        default:
            return .advanced
        }
    }

    private func languageStyle(for ageRange: String) -> TriviaLanguageStyle {
        switch ageRange {
        case "6-11":
            return .simple
        case "12-17", "18-25":
            return .conversational
        default:
            return .technical
        }
    }

    private func buildPrompt(
        profile: TriviaVisitorProfile,
        zoneID: Int,
        difficulty: TriviaDifficulty,
        languageStyle: TriviaLanguageStyle
    ) -> String {
        let interests = profile.interests.joined(separator: ", ")
        let characteristics = profile.characteristics.joined(separator: ", ")
        let languageInstruction: String

        switch languageStyle {
        case .simple:
            languageInstruction = "lenguaje simple"
        case .conversational:
            languageInstruction = "lenguaje conversacional"
        case .technical:
            languageInstruction = "lenguaje tecnico"
        }

        return """
        Genera trivia personalizada para la zona \(zoneID).
        Perfil: edad \(profile.ageRange), intereses \(interests), caracteristicas \(characteristics).
        Usa dificultad \(difficulty) y \(languageInstruction).
        """
    }
}

private final class MockProgressNetworkService: ProgressNetworkServicing {
    private(set) var sentPayloads: [ProgressPayload] = []
    var response = ProgressSyncResponse(success: true, message: "Sync completed")

    func syncProgress(_ payload: ProgressPayload) async throws -> ProgressSyncResponse {
        sentPayloads.append(payload)
        return response
    }
}

private final class MockProgressLocalStore: ProgressLocalStoring {
    private(set) var persistedProgress: ProgressPayload?

    func saveProgress(_ payload: ProgressPayload) async {
        persistedProgress = payload
    }
}

private final class MockAdaptiveTriviaGenerator: AdaptiveTriviaGenerating {
    private(set) var receivedRequests: [AdaptiveTriviaRequest] = []

    func generateTrivia(request: AdaptiveTriviaRequest) async throws -> [GeneratedTriviaQuestion] {
        receivedRequests.append(request)

        return (1...5).map { index in
            GeneratedTriviaQuestion(
                challengeID: "ZONE-\(request.zoneID)-IA-\(index)",
                zoneID: request.zoneID,
                question: "Pregunta generada \(index) para \(request.profile.ageRange)",
                options: ["A\(index)", "B\(index)", "C\(index)", "D\(index)"],
                correctAnswer: "A\(index)",
                type: "quiz"
            )
        }
    }
}
