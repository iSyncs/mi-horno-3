// MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var lm: LocalizationManager
    @StateObject private var challengesVM = ChallengesViewModel()

    var body: some View {
        let shouldHideTabBar = router.activeTab == .challenges &&
            (challengesVM.expandedZone != nil || challengesVM.activeFlow != nil)

        ZStack(alignment: .bottom) {
            Group {
                switch router.activeTab {
                case .home:        HomeView()
                case .challenges:  ChallengesView().environmentObject(challengesVM).environmentObject(lm)
                case .map:         MapSectionView()
                case .translation: TranslationView()
                case .profile:     ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: shouldHideTabBar ? 0 : 90)
            }
            // ⚠️ Sin .animation aquí — cualquier animación en el Group
            // causa que el ZStack recalcule tamaños y achique el tabbar

            if !shouldHideTabBar {
                H3TabBar()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .animation(.easeInOut(duration: 0.22), value: shouldHideTabBar)
    }
}

struct H3TabBar: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases) { tab in
                Button {
                    router.navigateTo(tab)
                } label: {
                    VStack(spacing: 3) {
                        ZStack {
                            if router.activeTab == tab {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.h3Orange.opacity(0.15))
                                    .frame(width: 48, height: 30)
                            }
                            Image(systemName: tab.rawValue)
                                .font(.system(size: 19,
                                              weight: router.activeTab == tab ? .semibold : .regular))
                                .foregroundColor(router.activeTab == tab
                                                 ? .h3Orange : Color.h3Sub(scheme))
                        }
                        Text(tab.label(lm: lm))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(router.activeTab == tab
                                             ? .h3Orange : Color.h3Sub(scheme))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 30)
        .background(
            ZStack(alignment: .top) {
                Color.h3Card(scheme)
                Rectangle().fill(Color.h3Separator(scheme)).frame(height: 0.5)
            }
        )
        .cornerRadius(28, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(scheme == .dark ? 0.4 : 0.08), radius: 20, x: 0, y: -4)
        .contentShape(Rectangle())
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppRouter())
        .environmentObject(LocalizationManager.shared)
        .environmentObject(ChallengesViewModel())
        .preferredColorScheme(.dark)
}
