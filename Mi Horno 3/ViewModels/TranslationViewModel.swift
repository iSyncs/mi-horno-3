import Foundation
import Combine
import SwiftUI
import AVFoundation
import Speech
import Vision
import Translation
import NaturalLanguage

// MARK: - Tipos

enum TranslationFeature: Equatable {
    case none, subtitles, visual, conversation
}
enum ConversationSide { case top, bottom }

// MARK: - TranslationViewModel

@MainActor
final class TranslationViewModel: NSObject, ObservableObject {

    // ── Subtítulos ────────────────────────────────────────────────────
    @Published var activeFeature: TranslationFeature = .none
    @Published var liveTranscript: String        = ""
    @Published var translatedTranscript: String  = ""   // SubtitlesView observa esto
    @Published var isListening: Bool             = false
    @Published var permissionDenied: Bool        = false

    // ── Conversación 1:1 ──────────────────────────────────────────────
    @Published var liveSpanishText: String       = ""
    @Published var translatedSpanishText: String = ""
    @Published var liveVisitorText: String       = ""
    @Published var translatedVisitorText: String = ""
    var spanishText: String { translatedVisitorText }
    var visitorText: String { translatedSpanishText }
    @Published var spanishListening: Bool = false
    @Published var visitorListening: Bool = false

    // ── Visual (OCR) ──────────────────────────────────────────────────
    @Published var visualResult: String   = ""
    @Published var visualDetected: String = ""
    @Published var isCapturing: Bool      = false
    private var lastVisionTime: Date      = .distantPast
    private let visionInterval: TimeInterval = 1.8

    // ── Audio ─────────────────────────────────────────────────────────
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    // var en lugar de let — se recrea en cada sesión para evitar estado corrupto
    private var audioEngine = AVAudioEngine()
    private var pauseTimer: Timer?
    private var pendingPartialText: String = ""

    // ── Idioma del visitante ──────────────────────────────────────────
    var deviceLanguage: String     { LocalizationManager.shared.deviceLanguage }
    var deviceLanguageName: String { LocalizationManager.shared.deviceLanguageName }

    // ─────────────────────────────────────────────
    // MARK: Permisos
    // ─────────────────────────────────────────────

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.permissionDenied = (status != .authorized)
            }
        }
        AVAudioApplication.requestRecordPermission { _ in }
        Task { await warmUpSessions() }
    }

    private func warmUpSessions() async {
        let lang = deviceLanguage
        guard lang != "es" else { return }
        NotificationCenter.default.post(name: .h3NeedSession,
            object: H3SessionRequest(sourceLang: "es", targetLang: lang))
        NotificationCenter.default.post(name: .h3NeedSession,
            object: H3SessionRequest(sourceLang: lang, targetLang: "es"))
    }

    // ─────────────────────────────────────────────
    // MARK: Traducción
    // ─────────────────────────────────────────────

    private func translate(text: String, from: String, to: String,
                            completion: @escaping (String) -> Void) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty, from != to else {
            completion(text); return
        }
        Task {
            let result = await TranslationSessionManager.shared.translate(
                text: text, from: from, to: to)
            await MainActor.run { completion(result) }
        }
    }

    // ─────────────────────────────────────────────
    // MARK: 1. SUBTÍTULOS EN VIVO
    //
    // Flujo:
    //   SubtitlesView setea vm.activeFeature = .subtitles
    //   SubtitlesView llama vm.startSubtitleListening()
    //   VM escucha es-MX → cada resultado parcial → traduce → translatedTranscript
    //   SubtitlesView observa translatedTranscript con onChange
    //   SubtitlesView llama vm.stopAudio() cuando el usuario para
    // ─────────────────────────────────────────────

    func toggleSubtitles() {
        if activeFeature == .subtitles { stopAudio(); activeFeature = .none }
        else { activeFeature = .subtitles }
    }

    func startSubtitleListening() {
        guard activeFeature == .subtitles else { return }
        liveTranscript       = ""
        translatedTranscript = ""

        // Paso 1: limpiar cualquier sesión anterior completamente
        fullTearDown()

        // Paso 2: crear reconocedor en español
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
        guard let recognizer, recognizer.isAvailable else {
            liveTranscript = LocalizationManager.shared.s(L.subtitlesNoSpeech)
            return
        }
        speechRecognizer = recognizer

        // Paso 3: configurar sesión de audio
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .record, mode: .measurement, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { return }

        // Paso 4: engine nuevo + tap limpio
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode

        // CRÍTICO: quitar tap siempre antes de instalar
        // inputNode es un singleton del hardware — si quedó un tap de la
        // sesión anterior, installTap falla silenciosamente y no hay audio.
        inputNode.removeTap(onBus: 0)

        let format = inputNode.outputFormat(forBus: 0)

        // Paso 5: request de reconocimiento
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation            = true
        recognitionRequest = request

        // Paso 6: tap → alimenta el reconocedor con audio
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        // Paso 7: arrancar engine
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            inputNode.removeTap(onBus: 0)
            return
        }

        // Paso 8: tarea de reconocimiento
        // → cada resultado parcial: traduce es→deviceLanguage → translatedTranscript
        // → SubtitlesView recibe el onChange y muestra el texto con efecto Aladdin
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.liveTranscript = text
                    // Traducir cada parcial — SubtitlesView tiene su propio sentenceTimer
                    self.translate(text: text, from: "es", to: self.deviceLanguage) { translated in
                        self.translatedTranscript = translated
                    }
                    // isFinal: el reconocedor terminó su ventana de 60s
                    // Solo paramos el audio — SubtitlesView decide si reiniciar
                    if result.isFinal {
                        self.stopAudioOnly()
                    }
                }
            }

            if error != nil {
                Task { @MainActor in self.stopAudioOnly() }
            }
        }
    }

    // ─────────────────────────────────────────────
    // MARK: 2. VISUAL (OCR) — sin cambios
    // ─────────────────────────────────────────────

    func toggleVisual() {
        if activeFeature == .visual { activeFeature = .none; visualResult = "" }
        else { activeFeature = .visual; visualResult = ""; visualDetected = "" }
    }

    func processRecognizedText(_ text: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, !isCapturing else { return }
        let lastWords = visualDetected.split(separator: " ").prefix(3).joined(separator: " ")
        let newWords  = cleaned.split(separator: " ").prefix(3).joined(separator: " ")
        guard newWords != lastWords else { return }
        isCapturing    = true
        visualDetected = cleaned
        translate(text: cleaned, from: "es", to: deviceLanguage) { [weak self] translated in
            guard let self else { return }
            self.visualResult = translated
            self.isCapturing  = false
        }
    }

    func processLiveFrame(_ pixelBuffer: CVPixelBuffer) {
        guard activeFeature == .visual, !isCapturing else { return }
        let now = Date()
        guard now.timeIntervalSince(lastVisionTime) >= visionInterval else { return }
        lastVisionTime = now
        isCapturing    = true
        let request = VNRecognizeTextRequest { [weak self] req, _ in
            guard let self else { return }
            let recognized = (req.results as? [VNRecognizedTextObservation] ?? [])
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespaces)
            guard !recognized.isEmpty else {
                Task { @MainActor in self.isCapturing = false }
                return
            }
            Task { @MainActor in self.visualDetected = recognized }
            self.translate(text: recognized, from: "es", to: self.deviceLanguage) { translated in
                Task { @MainActor in
                    self.visualResult = translated
                    self.isCapturing  = false
                }
            }
        }
        request.recognitionLevel       = .fast
        request.recognitionLanguages   = ["es-MX", "es", "en"]
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        DispatchQueue.global(qos: .userInitiated).async { try? handler.perform([request]) }
    }

    // ─────────────────────────────────────────────
    // MARK: 3. CONVERSACIÓN 1:1
    // ─────────────────────────────────────────────

    func toggleConversation() {
        if activeFeature == .conversation { stopAudio(); activeFeature = .none }
        else {
            activeFeature         = .conversation
            liveSpanishText       = ""; translatedSpanishText = ""
            liveVisitorText       = ""; translatedVisitorText = ""
        }
    }

    func startSpanishListening() {
        guard !spanishListening else { stopAudio(); spanishListening = false; return }
        stopAudio()                               // primero parar (resetea flags)
        spanishListening = true; visitorListening = false  // luego setear
        liveSpanishText = ""; pendingPartialText = ""

        startConversationRecognition(locale: Locale(identifier: "es-MX")) { [weak self] text, isFinal in
            guard let self else { return }
            self.liveSpanishText    = text
            self.pendingPartialText = text
            self.resetPauseTimer {
                self.translateBlock(self.pendingPartialText, from: "es", to: self.deviceLanguage) {
                    self.translatedSpanishText = $0
                }
            }
            if isFinal {
                self.pauseTimer?.invalidate()
                self.translateBlock(text, from: "es", to: self.deviceLanguage) {
                    self.translatedSpanishText = $0
                }
                self.stopAudio(); self.spanishListening = false
            }
        }
    }

    func startVisitorListening() {
        guard !visitorListening else { stopAudio(); visitorListening = false; return }
        stopAudio()                               // primero parar (resetea flags)
        visitorListening = true; spanishListening = false  // luego setear
        liveVisitorText = ""; pendingPartialText = ""

        startConversationRecognition(locale: Locale(identifier: deviceLanguage)) { [weak self] text, isFinal in
            guard let self else { return }
            self.liveVisitorText    = text
            self.pendingPartialText = text
            self.resetPauseTimer {
                self.translateBlock(self.pendingPartialText, from: self.deviceLanguage, to: "es") {
                    self.translatedVisitorText = $0
                }
            }
            if isFinal {
                self.pauseTimer?.invalidate()
                self.translateBlock(text, from: self.deviceLanguage, to: "es") {
                    self.translatedVisitorText = $0
                }
                self.stopAudio(); self.visitorListening = false
            }
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Motor conversación
    // ─────────────────────────────────────────────

    private func startConversationRecognition(
        locale: Locale,
        onResult: @escaping (String, Bool) -> Void
    ) {
        fullTearDown()

        let recognizer = SFSpeechRecognizer(locale: locale)
        guard let recognizer, recognizer.isAvailable else { return }
        speechRecognizer = recognizer

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .record, mode: .measurement, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { return }

        audioEngine = AVAudioEngine()
        let node = audioEngine.inputNode
        node.removeTap(onBus: 0)  // siempre limpiar antes de instalar
        let fmt = node.outputFormat(forBus: 0)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation            = true
        recognitionRequest = request

        node.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buf, _ in
            self?.recognitionRequest?.append(buf)
        }

        do { try audioEngine.start(); isListening = true }
        catch { node.removeTap(onBus: 0); return }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                Task { @MainActor in
                    onResult(result.bestTranscription.formattedString, result.isFinal)
                }
            }
            if error != nil || result?.isFinal == true {
                Task { @MainActor in self.stopAudio() }
            }
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Helpers
    // ─────────────────────────────────────────────

    private func translateBlock(_ text: String, from: String, to: String,
                                 completion: @escaping (String) -> Void) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        translate(text: text, from: from, to: to, completion: completion)
    }

    private func resetPauseTimer(onFire: @escaping () -> Void) {
        pauseTimer?.invalidate()
        pauseTimer = Timer.scheduledTimer(
            withTimeInterval: 1.8, repeats: false
        ) { _ in Task { @MainActor in onFire() } }
    }

    // ─────────────────────────────────────────────
    // MARK: Limpieza de audio
    // ─────────────────────────────────────────────

    /// Desmonta completamente el engine y la sesión de reconocimiento.
    /// Se llama SIEMPRE antes de crear una nueva sesión.
    private func fullTearDown() {
        pauseTimer?.invalidate()
        pauseTimer = nil
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask    = nil
        // Parar engine si corre
        if audioEngine.isRunning { audioEngine.stop() }
        // Quitar tap SIEMPRE — inputNode es singleton del hardware.
        // Hacerlo aunque el engine no esté corriendo.
        audioEngine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(
            false, options: .notifyOthersOnDeactivation)
    }

    /// Para audio sin tocar activeFeature (subtítulos: la view decide cuándo reiniciar)
    func stopAudioOnly() {
        fullTearDown()
        isListening = false
    }

    /// Para todo y resetea flags de conversación
    func stopAudio() {
        fullTearDown()
        isListening      = false
        spanishListening = false
        visitorListening = false
    }
}
