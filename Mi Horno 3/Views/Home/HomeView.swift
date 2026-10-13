// HomeView.swift
// Coordinator que ensambla las secciones del Home (sin ProgressSection — movida a Perfil)

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var lm: LocalizationManager
    @StateObject private var vm = HomeViewModel()
    @Environment(\.colorScheme) var scheme
    @State private var showAssistant = false
    @State private var showSensory = false

    var body: some View {
        ZStack {
            Color.h3BG(scheme).ignoresSafeArea()
            Circle()
                .fill(Color.h3Orange.opacity(scheme == .dark ? 0.10 : 0.06))
                .frame(width: 320).offset(x: 160, y: -120).blur(radius: 70).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HomeHeader(vm: vm)
                    SuggestionsSection(vm: vm)
                    ExploreSection(showAssistant: $showAssistant, showSensory: $showSensory)
                    Spacer(minLength: 110)
                }
            }
        }
        .fullScreenCover(isPresented: $showAssistant) {
            AssistantView().environmentObject(lm)
        }
        .sheet(isPresented: $showSensory) {
            SensoryView()
                .environmentObject(lm)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppRouter())
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.dark)
}
