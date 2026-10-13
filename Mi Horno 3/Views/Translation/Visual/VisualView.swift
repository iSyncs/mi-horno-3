// VisualView.swift
// Descripción visual: DataScannerViewController (VisionKit) → Apple Translation

import SwiftUI
import Combine
import AVFoundation
import Speech
import Vision
import VisionKit
import Translation

// ─────────────────────────────────────────────

// MARK: - 2. Descripción visual
// ─────────────────────────────────────────────
struct VisualView: View {
    @EnvironmentObject var lm: LocalizationManager
    @ObservedObject var vm: TranslationViewModel
    @State private var isAvailable = DataScannerViewController.isSupported &&
                                      DataScannerViewController.isAvailable
    @State private var resultVisible = false

    private let blue = Color(hex: "#0A84FF")

    var body: some View {
        ZStack {
            if isAvailable {
                DataScannerView(vm: vm).ignoresSafeArea()
            } else {
                FallbackCameraView(vm: vm).ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // ── Top bar ──────────────────────────────────────
                HStack {
                    Button { vm.toggleVisual() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(.black.opacity(0.5))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))
                    }

                    Spacer()
                    // Balance button with invisible placeholder
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)

                Spacer()

                // ── Translated text panel ────────────────────────
                if !vm.visualResult.isEmpty {
                    TranslatedResultPanel(
                        text: vm.visualResult,
                        isLoading: vm.isCapturing,
                        accentColor: blue
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: vm.visualResult.isEmpty)
        }
    }
}

// MARK: - Translated Result Panel
struct TranslatedResultPanel: View {
    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme
    let text: String
    let isLoading: Bool
    let accentColor: Color

    @State private var appeared = false
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header row ────────────────────────────────────────
            HStack(spacing: 8) {
                // Ícono + label
                HStack(spacing: 5) {
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(accentColor)
                    // Sin uppercase — texto normal con mayúscula inicial
                    Text(lm.s(L.translationVisualResult))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(accentColor.opacity(0.15))
                .clipShape(Capsule())

                Spacer()

                if isLoading {
                    HStack(spacing: 4) {
                        ProgressView()
                            .tint(accentColor)
                            .scaleEffect(0.6)
                        Text("...")
                            .font(.system(size: 10))
                            .foregroundColor(accentColor.opacity(0.7))
                    }
                }
            }
            .padding(.bottom, 14)

            // ── Texto traducido ────────────────────────────────────
            // Minúsculas normales — sin .uppercased() ni .textCase
            // Color adaptativo: blanco en dark, casi negro en light
            Text(text)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(scheme == .dark ? .white : Color(hex: "#1A1A1A"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(textOpacity)
                .offset(y: textOffset)

            // ── Línea decorativa inferior ─────────────────────────
            HStack {
                RoundedRectangle(cornerRadius: 1)
                    .fill(accentColor.opacity(0.3))
                    .frame(width: 32, height: 2)
                Spacer()
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                // Glassmorphism adaptativo — oscuro en dark, claro en light
                RoundedRectangle(cornerRadius: 22)
                    .fill(.regularMaterial)

                // Overlay de color según modo
                RoundedRectangle(cornerRadius: 22)
                    .fill(scheme == .dark
                        ? Color.black.opacity(0.45)
                        : Color.white.opacity(0.60))

                // Borde superior con acento
                VStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.6), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1.5)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 22))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: scheme == .dark ? .black.opacity(0.35) : .black.opacity(0.12),
                radius: 20, y: 8)
        .onAppear { animateIn() }
        .onChange(of: text) { _ in
            textOpacity = 0; textOffset = 8
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75).delay(0.05)) {
                textOpacity = 1; textOffset = 0
            }
        }
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75).delay(0.05)) {
            appeared = true
            textOpacity = 1
            textOffset = 0
        }
    }
}

// ─────────────────────────────────────────────
// DataScannerViewController wrapper
// ─────────────────────────────────────────────
struct DataScannerView: UIViewControllerRepresentable {
    @ObservedObject var vm: TranslationViewModel

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ vc: DataScannerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(vm: vm) }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let vm: TranslationViewModel
        private var lastProcessed: Date = .distantPast
        private let throttle: TimeInterval = 1.2

        init(vm: TranslationViewModel) { self.vm = vm }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didUpdate updatedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            let now = Date()
            guard now.timeIntervalSince(lastProcessed) >= throttle else { return }
            lastProcessed = now
            let texts = allItems.compactMap { item -> String? in
                if case .text(let t) = item { return t.transcript }
                return nil
            }
            guard !texts.isEmpty else { return }
            let fullText = texts.joined(separator: " ")
            Task { @MainActor in self.vm.processRecognizedText(fullText) }
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didTapOn item: RecognizedItem) {
            if case .text(let t) = item {
                Task { @MainActor in self.vm.processRecognizedText(t.transcript) }
            }
        }
    }
}

// ─────────────────────────────────────────────
// Fallback for older devices
// ─────────────────────────────────────────────
struct FallbackCameraView: UIViewRepresentable {
    @ObservedObject var vm: TranslationViewModel

    func makeCoordinator() -> Coordinator { Coordinator(vm: vm) }
    func makeUIView(context: Context) -> FallbackCameraUIView {
        let v = FallbackCameraUIView()
        v.configure(delegate: context.coordinator)
        return v
    }
    func updateUIView(_ uiView: FallbackCameraUIView, context: Context) {}

    class FallbackCameraUIView: UIView {
        private var session: AVCaptureSession?
        private var previewLayer: AVCaptureVideoPreviewLayer?
        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = bounds
        }
        func configure(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
            let s = AVCaptureSession()
            s.sessionPreset = .high
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let inp = try? AVCaptureDeviceInput(device: dev), s.canAddInput(inp) else { return }
            s.addInput(inp)
            let out = AVCaptureVideoDataOutput()
            out.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
            out.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "h3.fallback.camera"))
            out.alwaysDiscardsLateVideoFrames = true
            if s.canAddOutput(out) { s.addOutput(out) }
            let pl = AVCaptureVideoPreviewLayer(session: s)
            pl.videoGravity = .resizeAspectFill
            self.layer.addSublayer(pl)
            previewLayer = pl; session = s
            DispatchQueue.global(qos: .userInitiated).async { s.startRunning() }
        }
        deinit { session?.stopRunning() }
    }

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let vm: TranslationViewModel
        init(vm: TranslationViewModel) { self.vm = vm }
        func captureOutput(_ output: AVCaptureOutput,
                           didOutput sampleBuffer: CMSampleBuffer,
                           from connection: AVCaptureConnection) {
            guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            CVPixelBufferLockBaseAddress(pb, .readOnly)
            let copy = pb
            CVPixelBufferUnlockBaseAddress(pb, .readOnly)
            Task { @MainActor in self.vm.processLiveFrame(copy) }
        }
    }
}

// ─────────────────────────────────────────────

#Preview {
    VisualView(vm: TranslationViewModel())
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.dark)
}
