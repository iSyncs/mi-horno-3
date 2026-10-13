import SwiftUI

struct MuseumNavCameraContainerView: View {
    @EnvironmentObject var lm: LocalizationManager
    @Bindable var viewModel: MuseumNavViewModel
    var isScanningEnabled: Bool = true
    var blurRadius: CGFloat = 0

    var body: some View {
        ZStack {
            if viewModel.isCameraErrorActive {
                unavailableCameraPlaceholder
                    .blur(radius: blurRadius)
            } else {
                CameraPreview(session: viewModel.camera.session)
                    .blur(radius: blurRadius)
            }

            if isScanningEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Label(lm.s(L.mapScanTitle), systemImage: "qrcode.viewfinder")
                        .font(.system(size: 14, weight: .semibold))

                    Text(viewModel.scanStatusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .foregroundStyle(.white)
                .padding(16)
                .background(.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)
            }
        }
        .onAppear {
            if isScanningEnabled {
                viewModel.startCamera()
            } else {
                viewModel.stopCamera()
            }
        }
        .onChange(of: isScanningEnabled) { _, isEnabled in
            if isEnabled {
                viewModel.startCamera()
            } else {
                viewModel.stopCamera()
            }
        }
        .onDisappear {
            viewModel.stopCamera()
        }
    }

    private var unavailableCameraPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(hex: "#1B1B1B")],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 14) {
                Image(systemName: "camera.slash.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))

                Text(lm.s(L.mapScanTitle))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Text(viewModel.scanStatusText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }
}
