// HomeHeader.swift
import SwiftUI

struct HomeHeader: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var lm: LocalizationManager
    @ObservedObject var vm: HomeViewModel
    @Environment(\.colorScheme) var scheme

    // Iniciales fallback desde el nombre del router
    private var fallbackInitials: String {
        let parts = router.userName.split(separator: " ", maxSplits: 1)
        let f = String(parts.first?.prefix(1) ?? "V").uppercased()
        let l = parts.count > 1 ? String(parts[1].prefix(1)).uppercased() : ""
        return f + l
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(lm.s(vm.greetingKey))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.h3Sub(scheme))
                Text(router.userName.isEmpty ? lm.s(L.homeVisitor) : router.userName)
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(Color.h3Text(scheme))
            }
            Spacer()

            // Avatar — refleja el config guardado en AppRouter en tiempo real
            avatarBadge
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 26)
    }

    @ViewBuilder
    private var avatarBadge: some View {
        if router.hasCustomPhoto {
            // Config personalizado: usa AvatarShapeView + AvatarFrameView
            ZStack {
                AvatarShapeView(config: router.photoConfig, size: 48)
                AvatarFrameView(config: router.photoConfig, size: 54)
            }
            .frame(width: 54, height: 54)
        } else {
            // Fallback original con iniciales
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.h3OrangeLight, Color.h3Orange],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.h3Orange.opacity(0.35), radius: 8)
                Text(fallbackInitials)
                    .font(.system(size: fallbackInitials.count > 1 ? 16 : 20, weight: .black))
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    HomeHeader(vm: HomeViewModel())
        .environmentObject({
            let r = AppRouter()
            r.userName = "Joel García"
            r.userEmail = "joel@horno3.mx"
            return r
        }())
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.dark)
        .background(Color.h3Black)
}
