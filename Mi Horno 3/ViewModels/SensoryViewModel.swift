// SensoryViewModel.swift
import SwiftUI
import Combine

// MARK: - Mensaje del chat

struct SensoryMessage: Identifiable {
    let id = UUID()
    let role: SensoryRole
    let text: String
    let tip: String?
    let level: String?
    let timestamp: Date = Date()
}

enum SensoryRole { case user, assistant }

// MARK: - ViewModel

final class SensoryViewModel: ObservableObject {

    // MARK: - Published

    @Published var messages: [SensoryMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isSimulatorMode: Bool = false

    // MARK: - Private

    private let service = SensoryAdvisorService()
    private let lm = LocalizationManager.shared
    private let baseURL = Config.baseURL
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 15
        return URLSession(configuration: c)
    }()

    // MARK: - Init

    init() {
        isSimulatorMode = !SensoryAdvisorService.isModelAvailable
    }

    // MARK: - Quick suggestions — siempre via lm.s() para traducción automática

    var quickSuggestions: [String] {
        [
            lm.s(L.sensoryQ1),
            lm.s(L.sensoryQ2),
            lm.s(L.sensoryQ3),
            lm.s(L.sensoryQ4)
        ]
    }

    // MARK: - Send

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isLoading else { return }

        messages.append(SensoryMessage(role: .user, text: text, tip: nil, level: nil))
        inputText = ""
        isLoading = true
        errorMessage = nil

        Task { await registerVisit(roomName: "General") }
        
        Task { @MainActor in
            await fetchResponse(for: text)
        }
    }

    // MARK: - BD: Registrar visita sensorial
 
    private func registerVisit(roomName: String) async {
        guard let token = UserDefaults.standard.string(forKey: "h3_access_token"),
              let url   = URL(string: baseURL + "/sensory/visit") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)",  forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "room_name":        roomName,
            "duration_seconds": 0
        ])
        _ = try? await session.data(for: req)
    }

    // MARK: - Fetch

    @MainActor
    private func fetchResponse(for question: String) async {
        do {
            let response = try await service.ask(question)

            // Si el dispositivo no es español, traducimos la respuesta del modelo
            // (que siempre responde en español según el system prompt)
            let translatedAnswer = await translateIfNeeded(response.answer ?? "")
            let translatedTip    = response.tip != nil
                ? await translateIfNeeded(response.tip ?? "")
                : nil

            // El nivel lo normalizamos a la clave L para que lm.s() lo traduzca
            let localizedLevel = localizeLevel(response.overallLevel)

            messages.append(SensoryMessage(
                role: .assistant,
                text: translatedAnswer,
                tip: translatedTip,
                level: localizedLevel
            ))
        } catch {
            messages.append(SensoryMessage(
                role: .assistant,
                text: lm.s(L.sensoryErrorMsg),
                tip: nil,
                level: nil
            ))
        }
        isLoading = false
    }

    // MARK: - Traducción dinámica de respuestas del modelo

    private func translateIfNeeded(_ text: String) async -> String {
        guard lm.needsTranslation else { return text }
        return await TranslationSessionManager.shared.translate(
            text: text,
            from: "es",
            to: lm.deviceLanguage
        )
    }

    /// Convierte el level string del backend ("tranquila"/"moderada"/"intensa")
    /// a la clave L para que la vista lo muestre traducido con lm.s()
    private func localizeLevel(_ level: String?) -> String? {
        switch level?.lowercased() {
        case "tranquila": return L.sensoryLevelTranquila
        case "moderada":  return L.sensoryLevelModerada
        case "intensa":   return L.sensoryLevelIntensa
        default:          return level
        }
    }

    // MARK: - Clear

    func clearChat() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            messages = []
            errorMessage = nil
        }
    }

    // MARK: - Helpers

    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }
}
