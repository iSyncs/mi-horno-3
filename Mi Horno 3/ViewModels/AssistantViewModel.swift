// AssistantViewModel.swift
// LLM: Qwen2.5-0.5B via MLXLLM — on-device, offline después de la primera descarga

import Foundation
import SwiftUI
import Combine
import AVFoundation
import Speech
import MLX
import MLXLLM
import MLXLMCommon
import Tokenizers

// MARK: - Estado

enum AssistantState {
    case downloadingModel(Double)
    case loadingModel
    case idle
    case listening
    case readyToSend
    case processing
    case responding
}

extension AssistantState: Equatable {
    static func == (lhs: AssistantState, rhs: AssistantState) -> Bool {
        switch (lhs, rhs) {
        case (.downloadingModel(let a), .downloadingModel(let b)): return a == b
        case (.loadingModel, .loadingModel), (.idle, .idle),
             (.listening, .listening), (.readyToSend, .readyToSend),
             (.processing, .processing), (.responding, .responding): return true
        default: return false
        }
    }
}

// MARK: - Mensaje del chat

struct ChatMessage: Identifiable {
    let id        = UUID()
    let role:     ChatRole
    let text:     String
    let timestamp = Date()
}
enum ChatRole { case user, assistant }

// MARK: - AssistantViewModel

@MainActor
final class AssistantViewModel: NSObject, ObservableObject {

    // ── UI ────────────────────────────────────────────────────────────
    @Published var state: AssistantState      = .downloadingModel(0)
    @Published var messages: [ChatMessage]    = []
    @Published var currentTranscript: String  = ""
    @Published var streamingText: String      = ""
    @Published var permissionDenied: Bool     = false

    // ── LLM — singleton para no recargar cada vez ─────────────────────
    private static var sharedContainer: ModelContainer?
    private var modelContainer: ModelContainer? {
        get { AssistantViewModel.sharedContainer }
        set { AssistantViewModel.sharedContainer = newValue }
    }

    private let modelConfig = ModelConfiguration(
        id: "mlx-community/Qwen2.5-0.5B-Instruct-4bit"
    )

    private let loadingPhrases = [
        "Consultando el archivo histórico…",
        "Activando el asistente del Horno³…",
        "Preparando la guía del museo…",
        "Cargando conocimiento sobre el acero…",
        "El Gigante Despertando…",
        "Iniciando el motor de IA…"
    ]
    @Published var currentLoadingPhrase: String = ""
    private var phraseTimer: Timer?

    // ── Audio ─────────────────────────────────────────────────────────
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()

    // ── Idioma ────────────────────────────────────────────────────────
    private var visitorLanguage: String     { LocalizationManager.shared.deviceLanguage }
    private var visitorLanguageName: String { LocalizationManager.shared.deviceLanguageName }

    // MARK: - Init normal (app)

    override init() {
        super.init()
        currentLoadingPhrase = loadingPhrases.randomElement() ?? loadingPhrases[0]
        Task { await loadModel() }
    }

    // MARK: - Init para tests — no lanza loadModel ni AVAudio

    #if DEBUG
    init(skipModelLoad: Bool) {
        super.init()
        currentLoadingPhrase = loadingPhrases.first ?? ""
        // No lanzamos loadModel() — estado queda en .downloadingModel(0)
    }
    #endif

    // MARK: - Cargar modelo

    func loadModel() async {
        if modelContainer != nil {
            state = .idle
            return
        }

        startLoadingPhraseRotation()

        do {
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)

            modelContainer = try await LLMModelFactory.shared.loadContainer(
                configuration: modelConfig
            ) { [weak self] progress in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if progress.fractionCompleted < 1.0 {
                        self.state = .downloadingModel(progress.fractionCompleted)
                    } else {
                        self.state = .loadingModel
                    }
                }
            }

            stopLoadingPhraseRotation()
            state = .idle
            print("[MLXLLM] Modelo listo: \(modelConfig.id)")

        } catch {
            print("[MLXLLM] Error: \(error)")
            stopLoadingPhraseRotation()
            state = .idle
        }
    }

    private func startLoadingPhraseRotation() {
        phraseTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.currentLoadingPhrase = self.loadingPhrases.randomElement() ?? self.loadingPhrases[0]
            }
        }
    }

    private func stopLoadingPhraseRotation() {
        phraseTimer?.invalidate()
        phraseTimer = nil
    }

    // MARK: - FAB

    func fabTapped() {
        switch state {
        case .downloadingModel, .loadingModel: return
        case .idle, .responding:
            startListening(); state = .listening
        case .listening:
            stopListening()
            if currentTranscript.trimmingCharacters(in: .whitespaces).isEmpty {
                state = .idle
            } else {
                state = .readyToSend
                sendMessage()
            }
        case .readyToSend:
            sendMessage()
        case .processing:
            break
        }
    }

    func cancelTapped() {
        stopListening()
        currentTranscript = ""
        state = .idle
    }

    var shouldShowCancel: Bool {
        state == .listening || state == .readyToSend
    }

    var fabIcon: String {
        switch state {
        case .downloadingModel, .loadingModel: return "arrow.down.circle"
        case .idle, .responding:              return "mic.fill"
        case .listening:                      return "stop.fill"
        case .readyToSend:                    return "paperplane.fill"
        case .processing:                     return "ellipsis"
        }
    }

    var fabColor: Color {
        switch state {
        case .listening:                       return .red
        case .readyToSend:                     return .h3Orange
        case .responding:                      return Color(hex: "#30D158")
        case .downloadingModel, .loadingModel: return .gray
        default:                               return .h3Orange
        }
    }

    // MARK: - Permisos

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in self?.permissionDenied = (status != .authorized) }
        }
        AVAudioApplication.requestRecordPermission { _ in }
    }

    // MARK: - Enviar mensaje

    private func sendMessage() {
        let text = currentTranscript.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { state = .idle; return }
        messages.append(ChatMessage(role: .user, text: text))
        currentTranscript = ""
        streamingText     = ""
        state             = .processing
        Task { await generateResponse(userMessage: text) }
    }

    // MARK: - Generar respuesta

    private func generateResponse(userMessage: String) async {
        guard let container = modelContainer else { appendError(); return }

        state = .responding

        let systemPrompt = """
        \(MuseumContext.text)
        INSTRUCCIÓN CRÍTICA:
        - Responde SIEMPRE en \(visitorLanguageName). Sin excepción.
        - Máximo 2 oraciones cortas y claras.
        - Sé amable y entusiasta.
        - No uses caracteres especiales raros.
        - No repitas palabras ni frases.
        - Responde directamente sin preámbulos.
        """

        let chatMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user",   "content": userMessage]
        ]

        do {
            let result = try await container.perform { context in
                let input = try await context.processor.prepare(
                    input: .init(messages: chatMessages)
                )

                var lastTokenCount = 0

                let generateResult = try MLXLMCommon.generate(
                    input: input,
                    parameters: GenerateParameters(maxTokens: 150, temperature: 0.6),
                    context: context
                ) { tokens in
                    let newTokens = Array(tokens.suffix(tokens.count - lastTokenCount))
                    lastTokenCount = tokens.count

                    if !newTokens.isEmpty {
                        let newText = context.tokenizer.decode(tokens: newTokens)
                        Task { @MainActor in
                            self.streamingText += newText
                        }
                    }
                    return tokens.count >= 150 ? .stop : .more
                }

                return context.tokenizer.decode(tokens: generateResult.tokens)
            }

            let clean = cleanResponse(result)
            messages.append(ChatMessage(role: .assistant, text: clean))
            streamingText = ""
            state = .idle

        } catch {
            print("[MLXLLM] Error: \(error)")
            appendError()
        }
    }

    /// Limpia la respuesta del modelo eliminando tokens especiales y texto repetido
    private func cleanResponse(_ raw: String) -> String {
        var text = raw

        let specialTokens = ["<|im_end|>", "<|im_start|>", "<|endoftext|>",
                             "<|end|>", "</s>", "<s>", "[INST]", "[/INST]"]
        for token in specialTokens {
            text = text.replacingOccurrences(of: token, with: "")
        }

        if let range = text.range(of: "user\n", options: .caseInsensitive) {
            text = String(text[..<range.lowerBound])
        }
        if let range = text.range(of: "<|im_start|>", options: .caseInsensitive) {
            text = String(text[..<range.lowerBound])
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func appendError() {
        messages.append(ChatMessage(
            role: .assistant,
            text: LocalizationManager.shared.s(L.assistantError)
        ))
        streamingText = ""
        state = .idle
    }

    // MARK: - Reconocimiento de voz

    func startListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask    = nil

        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: visitorLanguage))
        if speechRecognizer == nil || speechRecognizer?.isAvailable == false {
            speechRecognizer = SFSpeechRecognizer(locale: .current)
        }
        guard let recognizer = speechRecognizer, recognizer.isAvailable else { return }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let req = recognitionRequest else { return }
        req.shouldReportPartialResults = true
        req.addsPunctuation            = true

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(
                true, options: .notifyOthersOnDeactivation)
        } catch { return }

        audioEngine = AVAudioEngine()
        let node = audioEngine.inputNode
        node.removeTap(onBus: 0)
        let fmt = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buf, _ in
            self?.recognitionRequest?.append(buf)
        }
        do { try audioEngine.start() } catch { node.removeTap(onBus: 0); return }

        recognitionTask = recognizer.recognitionTask(with: req) { [weak self] result, err in
            guard let self else { return }
            if let r = result {
                Task { @MainActor in self.currentTranscript = r.bestTranscription.formattedString }
            }
            if err != nil || result?.isFinal == true {
                Task { @MainActor in self.stopListening() }
            }
        }
    }

    func stopListening() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask    = nil
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(
            false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Test helpers

    #if DEBUG
    func cleanResponse_test(_ raw: String) -> String {
        cleanResponse(raw)
    }

    static func resetSharedContainerForTests() {
        sharedContainer = nil
    }

    static func sharedContainerIsNil() -> Bool {
        sharedContainer == nil
    }
    #endif
}
