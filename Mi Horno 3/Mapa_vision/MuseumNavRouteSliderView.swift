import SwiftUI

struct MuseumNavRouteSliderView: View {
    @EnvironmentObject var lm: LocalizationManager
    @Bindable var viewModel: MuseumNavViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lm.s(L.mapRoutes))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            Picker(lm.s(L.mapRoutes), selection: $viewModel.selectedRouteIndex) {
                ForEach(Array(viewModel.routes.enumerated()), id: \.offset) { index, route in
                    Text(viewModel.localizedRouteName(route)).tag(index)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 140)
            .clipped()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
