// MapView.swift
import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var lm: LocalizationManager
    @Environment(\.colorScheme) var scheme

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.6771, longitude: -100.2892),
        span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
    )

    var body: some View {
        ZStack(alignment: .top) {
            Map(coordinateRegion: $region, annotationItems: MuseumCatalog.attractions) { attr in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: attr.latitude, longitude: attr.longitude)) {
                    AttractionAnnotation(attraction: attr)
                }
            }
            .ignoresSafeArea()

            // Header pill
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Color.h3Orange).frame(width: 34, height: 34)
                        Image("horno3")
                            .resizable().scaledToFit()
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lm.s(L.mapMuseumName))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(scheme == .dark ? .white : Color(hex: "#111111"))
                        Text(lm.s(L.mapAddress))
                            .font(.system(size: 11))
                            .foregroundColor(scheme == .dark
                                             ? Color.white.opacity(0.6)
                                             : Color(hex: "#555555"))
                    }
                    Spacer()
                    Button {
                        if let url = URL(string: "maps://?ll=25.6771,-100.2892&q=Horno3+Museo+del+Acero") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.h3Orange)
                            Text(lm.s(L.mapDirections))
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.h3Orange)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                .padding(.horizontal, 16)
                .padding(.top, 60)
            }

            // Attractions legend
            VStack {
                Spacer()
                AttractionsLegend()
            }
        }
    }
}


#Preview {
    MapView()
        .environmentObject(LocalizationManager.shared)
}
