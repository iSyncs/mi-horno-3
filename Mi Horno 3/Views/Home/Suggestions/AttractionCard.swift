// AttractionCard.swift
// Card expandible con info de cada atracción del museo

import SwiftUI

struct AttractionCard: View {
    @EnvironmentObject var lm: LocalizationManager
    let attraction: Attraction
    @ObservedObject var vm: HomeViewModel
    @Environment(\.colorScheme) var scheme

    var isExpanded: Bool { vm.expandedAttractionID == attraction.id }
    var soon: Bool { vm.isShowSoon(attraction: attraction) }

    var body: some View {
        Button { vm.toggleExpanded(attraction.id) } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Icon + soon badge
                HStack {
                    ZStack {
                        Circle()
                            .fill(attraction.accentColor.opacity(0.15))
                            .frame(width: 42, height: 42)
                        Image(systemName: attraction.icon)
                            .font(.system(size: 18))
                            .foregroundColor(attraction.accentColor)
                    }
                    Spacer()
                    if soon {
                        Label(lm.s(L.attractionSoon), systemImage: "circle.fill")
                            .labelStyle(TrailingIconLabel())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.green.opacity(0.12))
                            .cornerRadius(8)
                    }
                }

                // Name + schedule
                VStack(alignment: .leading, spacing: 3) {
                    Text(lm.s(attraction.nameKey))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.h3Text(scheme))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    HStack(spacing: 4) {
                        Image(systemName: "clock").font(.system(size: 10))
                        Text(attraction.availableAllDay
                             ? lm.s(L.attractionAllDay)
                             : String(format: lm.s(L.attractionShowIn), vm.minutesUntilNextShow))
                            .font(.system(size: 11))
                    }
                    .foregroundColor(Color.h3Sub(scheme))
                }

                // Expanded detail
                if isExpanded {
                    Divider().background(Color.h3Separator(scheme))
                    Text(lm.s(attraction.descriptionKey))
                        .font(.system(size: 12))
                        .foregroundColor(Color.h3Sub(scheme))
                        .lineLimit(5)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.h3Orange)
                        Text(String(format: "%.4f, %.4f",
                                    attraction.latitude, attraction.longitude))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Color.h3Sub(scheme))
                    }
                    .padding(.top, 2)
                }
            }
            .padding(16)
            .frame(width: isExpanded ? 260 : 180)
            .h3Card()
        }
        .buttonStyle(.plain)
    }
}

struct TrailingIconLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.font(.system(size: 6))
            configuration.title
        }
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack(spacing: 14) {
            ForEach(MuseumCatalog.attractions) { attr in
                AttractionCard(attraction: attr, vm: HomeViewModel())
            }
        }
        .padding()
    }
    .environmentObject(LocalizationManager.shared)
    .preferredColorScheme(.dark)
    .background(Color.h3Black)
}
