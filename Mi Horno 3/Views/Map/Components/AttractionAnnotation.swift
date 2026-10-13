// AttractionAnnotation.swift
// Anotación en el mapa para cada atracción

import SwiftUI
import MapKit

struct AttractionAnnotation: View {
    @EnvironmentObject var lm: LocalizationManager
    let attraction: Attraction
    @State private var showLabel = false

    var body: some View {
        Button { withAnimation { showLabel.toggle() } } label: {
            VStack(spacing: 2) {
                if showLabel {
                    Text(lm.s(attraction.nameKey))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(attraction.accentColor)
                        .cornerRadius(8)
                        .transition(.scale.combined(with: .opacity))
                }
                ZStack {
                    Circle()
                        .fill(attraction.accentColor)
                        .frame(width: 34, height: 34)
                        .shadow(color: attraction.accentColor.opacity(0.5), radius: 6)
                    Image(systemName: attraction.icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
        }
    }
}


#Preview {
    let attr = MuseumCatalog.attractions[0]
    return Map(coordinateRegion: .constant(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.6771, longitude: -100.2892),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))),
        annotationItems: [attr]) { a in
        MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: a.latitude, longitude: a.longitude)) {
            AttractionAnnotation(attraction: a)
                .environmentObject(LocalizationManager.shared)
        }
    }
}
