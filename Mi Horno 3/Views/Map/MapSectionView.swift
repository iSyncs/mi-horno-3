import SwiftUI

struct MapSectionView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var lm: LocalizationManager
    @State private var museumNavViewModel = MuseumNavViewModel()
    @State private var isCameraPrimary = true
    @State private var activeControl: MapControlPanel?
    @State private var cameraBlurRadius: CGFloat = 0
    @State private var showMapIntro = false

    private static var hasShownIntroThisSession = false
    private let transitionDuration: Double = 0.30

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                panel(
                    content: MuseumNavCameraContainerView(
                        viewModel: museumNavViewModel,
                        isScanningEnabled: isCameraPrimary,
                        blurRadius: cameraBlurRadius
                    ),
                    isPrimary: isCameraPrimary,
                    in: proxy.size,
                    floatingYOffset: 60
                )
                .zIndex(isCameraPrimary ? 1 : 2)

                panel(
                    content: museumMapContent,
                    isPrimary: !isCameraPrimary,
                    in: proxy.size,
                    floatingYOffset: 60
                )
                .zIndex(isCameraPrimary ? 2 : 1)

                if !isCameraPrimary {
                    bottomOverlay
                        .zIndex(3)
                }
            }
            .animation(.easeInOut(duration: transitionDuration), value: isCameraPrimary)
            .onAppear {
                syncIndoorMapContext()
                showIntroIfNeeded()
            }
            .alert(lm.s(L.mapIntroTitle), isPresented: $showMapIntro) {
                Button(lm.s(L.mapIntroButton), role: .cancel) { }
            } message: {
                Text(lm.s(L.mapIntroMessage))
            }
            .onChange(of: museumNavViewModel.currentNode?.id) { _, _ in
                syncIndoorMapContext()
            }
            .onChange(of: museumNavViewModel.selectedFloor) { _, _ in
                syncIndoorMapContext()
            }
            .onChange(of: museumNavViewModel.selectedDestinationIndex) { _, _ in
                syncIndoorMapContext()
            }
            .onChange(of: museumNavViewModel.selectedRouteIndex) { _, _ in
                syncIndoorMapContext()
            }
        }
    }

    private var museumMapContent: some View {
        ZStack(alignment: .topLeading) {
            MuseumNavMiniMapView(viewModel: museumNavViewModel, isCompact: isCameraPrimary)
                .environmentObject(lm)
        }
    }

    private var bottomOverlay: some View {
        VStack(spacing: 12) {
            if let activeControl {
                controlPanel(for: activeControl)
                    .environmentObject(lm)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 12) {
                controlButton(title: lm.s(L.mapRoutes), panel: .routes, icon: "point.topleft.down.curvedto.point.bottomright.up")
                controlButton(title: lm.s(L.mapQuickDestination), panel: .destinations, icon: "mappin.and.ellipse")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private func controlPanel(for panel: MapControlPanel) -> some View {
        switch panel {
        case .routes:
            MuseumNavRouteSliderView(viewModel: museumNavViewModel)
        case .destinations:
            MuseumNavDestinationSliderView(viewModel: museumNavViewModel)
        }
    }

    private func controlButton(title: String, panel: MapControlPanel, icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
                activeControl = activeControl == panel ? nil : panel
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(activeControl == panel ? Color.h3Orange : Color.black.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func panel<Content: View>(
        content: Content,
        isPrimary: Bool,
        in containerSize: CGSize,
        floatingYOffset: CGFloat = 0
    ) -> some View {
        let horizontalMargin: CGFloat = 16
        let bottomMargin: CGFloat = 110
        let floatingWidth = min(containerSize.width * 0.44, 220)
        let floatingHeight = min(containerSize.height * 0.30, 240)

        let width = isPrimary ? containerSize.width : floatingWidth
        let height = isPrimary ? containerSize.height : floatingHeight
        let x = isPrimary ? containerSize.width / 2 : containerSize.width - horizontalMargin - (floatingWidth / 2)
        let y = isPrimary
            ? containerSize.height / 2
            : containerSize.height - bottomMargin - (floatingHeight / 2) + 20 + floatingYOffset

        return content
            .frame(width: width, height: height)
            .environmentObject(lm)
            .clipShape(RoundedRectangle(cornerRadius: isPrimary ? 0 : 28))
            .overlay {
                if !isPrimary {
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)

                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.clear)
                        .contentShape(RoundedRectangle(cornerRadius: 28))
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: transitionDuration)) {
                                togglePrimaryPanel()
                            }
                        }
                }
            }
            .shadow(color: .black.opacity(isPrimary ? 0 : 0.28), radius: 26, y: 14)
            .position(x: x, y: y)
        }
}

private extension MapSectionView {
    func showIntroIfNeeded() {
        guard !Self.hasShownIntroThisSession else { return }
        Self.hasShownIntroThisSession = true
        showMapIntro = true
    }

    func syncIndoorMapContext() {
        let currentNode = museumNavViewModel.currentNode
        let hasRealNode = (currentNode?.id ?? 0) > 0
        let localizedCurrentNodeName = currentNode.map { museumNavViewModel.localizedNodeName($0.name) }
        let localizedDestinationName = museumNavViewModel.selectedDestinationNode.map {
            museumNavViewModel.localizedNodeName($0.name)
        }

        router.updateIndoorMapContext(
            IndoorMapAssistanceContext(
                currentNodeID: hasRealNode ? currentNode?.id : nil,
                currentNodeName: hasRealNode ? localizedCurrentNodeName : nil,
                floorCode: (hasRealNode || museumNavViewModel.lastScannedQR != nil)
                    ? (currentNode?.floor ?? museumNavViewModel.selectedFloor).assistanceFloorCode
                    : nil,
                qrCode: currentNode?.qr ?? museumNavViewModel.lastScannedQR,
                x: hasRealNode ? currentNode.map { Double($0.x) } : nil,
                y: hasRealNode ? currentNode.map { Double($0.y) } : nil,
                selectedDestinationName: localizedDestinationName,
                selectedRouteName: museumNavViewModel.localizedRouteName(museumNavViewModel.selectedRouteName)
            )
        )

        museumNavViewModel.uploadCurrentUserLocationIfNeeded(userID: router.userId)
    }

    func togglePrimaryPanel() {
        if isCameraPrimary {
            cameraBlurRadius = 14
            isCameraPrimary = false
            activeControl = nil
            return
        }

        isCameraPrimary = true
        activeControl = nil

        Task {
            try? await Task.sleep(for: .seconds(transitionDuration))
            await MainActor.run {
                if isCameraPrimary {
                    withAnimation(.easeOut(duration: 0.18)) {
                        cameraBlurRadius = 0
                    }
                }
            }
        }
    }
}

private enum MapControlPanel {
    case routes
    case destinations
}

#Preview {
    MapSectionView()
        .environmentObject(LocalizationManager.shared)
}
