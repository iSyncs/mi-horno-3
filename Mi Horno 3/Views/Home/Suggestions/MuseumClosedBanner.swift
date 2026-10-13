// MuseumClosedBanner.swift
// Banner que aparece cuando el museo está cerrado

import SwiftUI

struct MuseumClosedBanner: View {
    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 22))
                .foregroundColor(.h3Orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(lm.s(L.museumClosedTitle))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.h3Text(scheme))
                Text(lm.s(L.museumSchedule))
                    .font(.system(size: 12))
                    .foregroundColor(Color.h3Sub(scheme))
            }
            Spacer()
        }
        .padding(16)
        .h3Card()
        .padding(.horizontal, 24)
    }
}

#Preview {
    MuseumClosedBanner()
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.dark)
        .background(Color.h3Black)
}
