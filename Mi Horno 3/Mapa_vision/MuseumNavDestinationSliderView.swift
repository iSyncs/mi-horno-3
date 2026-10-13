import SwiftUI

struct MuseumNavDestinationSliderView: View {
    @EnvironmentObject var lm: LocalizationManager
    @Bindable var viewModel: MuseumNavViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lm.s(L.mapQuickDestination))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            Picker(
                lm.s(L.mapQuickDestination),
                selection: Binding(
                    get: { viewModel.selectedDestinationIndex },
                    set: {
                        viewModel.selectedDestinationIndex = $0
                        viewModel.selectDestinationAtCurrentIndex()
                    }
                )
            ) {
                ForEach(Array(viewModel.destinations.enumerated()), id: \.offset) { index, destination in
                    Text(viewModel.localizedNodeName(destination)).tag(index)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 140)
            .clipped()
            .disabled(viewModel.destinations.isEmpty)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
