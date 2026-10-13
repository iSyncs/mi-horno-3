// AttractionsLegend.swift
// Leyenda inferior con chips de atracciones

import SwiftUI

struct AttractionsLegend: View {
    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lm.s(L.mapAttractions))
                .font(.system(size: 16, weight: .black))
                .foregroundColor(Color.h3Text(scheme))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MuseumCatalog.attractions) { attr in
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(attr.accentColor.opacity(0.18))
                                    .frame(width: 30, height: 30)
                                Image(systemName: attr.icon)
                                    .font(.system(size: 13))
                                    .foregroundColor(attr.accentColor)
                            }
                            Text(lm.s(attr.nameKey))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.h3Text(scheme))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.h3Card(scheme))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.07), radius: 4)
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 20, y: -4)
    }
}


#Preview {
    AttractionsLegend()
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.dark)
}
