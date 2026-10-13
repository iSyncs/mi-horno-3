// TranslationView.swift
import SwiftUI
import AVFoundation
import Speech
import Vision
import VisionKit
import Translation

struct TranslationView: View {
    @EnvironmentObject var lm: LocalizationManager
    @StateObject private var vm = TranslationViewModel()
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            Color.h3BG(scheme).ignoresSafeArea()
            switch vm.activeFeature {
            case .none:         TranslationMenuView(vm: vm)
            case .subtitles:    SubtitlesView(vm: vm)
            case .visual:       VisualView(vm: vm)
            case .conversation: ConversationView(vm: vm)
            }
        }
        .onAppear { vm.requestPermissions() }
        // Sin animación aquí — causaba que el tabbar se redimensionara
    }
}

#Preview {
    TranslationView()
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.dark)
}
