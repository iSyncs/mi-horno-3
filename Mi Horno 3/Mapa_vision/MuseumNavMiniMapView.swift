import SwiftUI
import UIKit

private struct FloorPlanMetrics {
    let viewportRect: CGRect
    let sourceRect: CGRect
    let scale: CGFloat
    let imageFrame: CGRect
}

private struct DebugMapCoordinate {
    let point: CGPoint
    let x: CGFloat
    let y: CGFloat
    let floor: MuseumNavFloor
}

private let renderedNodeOffset = CGSize(width: -40, height: 30)

// Herramientas utilizadas para acomodar los nodos.
// Mantener ocultas en la app final; activar solo durante ajustes manuales de coordenadas.
private let nodePlacementToolsEnabled = false

struct MuseumNavMiniMapView: View {
    @EnvironmentObject var lm: LocalizationManager
    let viewModel: MuseumNavViewModel
    var isCompact: Bool = false
    @State private var isSettingsExpanded = false
    @State private var zoomScale: CGFloat = 1
    @State private var pinchScale: CGFloat = 1
    @State private var contentOffset: CGSize = .zero
    @State private var dragTranslation: CGSize = .zero
    @State private var debugMapCoordinate: DebugMapCoordinate?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: isCompact ? 22 : 28)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#F3EEE5"), Color(hex: "#DDD1BF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: isCompact ? 22 : 28)
                    .stroke(Color(hex: "#BCA78B").opacity(0.7), lineWidth: 1)

                interactiveMap(in: proxy.size)

                mapLabels
                floorSelector

                settingsControls

                if !isCompact {
                    recenterFloatingButton(in: proxy.size)
                }

                if !isCompact,
                   let selectedNode = viewModel.selectedNode,
                   selectedNode.floor == viewModel.selectedFloor {
                    nodeDetailsBubble(for: selectedNode, in: proxy.size)
                }

                if nodePlacementToolsEnabled,
                   !isCompact,
                   let debugMapCoordinate,
                   debugMapCoordinate.floor == viewModel.selectedFloor {
                    mapCoordinateBubble(debugMapCoordinate, in: proxy.size)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: isCompact ? 22 : 28))
            .onChange(of: viewModel.selectedDestinationIndex) { _, _ in
                guard !isCompact else { return }
                guard let destinationNode = viewModel.selectedDestinationNode else { return }
                viewModel.selectNode(destinationNode)
                centerOnSelectedDestination(in: proxy.size)
            }
        }
    }

    @ViewBuilder
    private var mapLabels: some View {
        if !isCompact {
            VStack(alignment: .leading, spacing: 4) {
                Text(lm.s(L.mapMuseumIndoor))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "#35281F"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(viewModel.currentNode.map { viewModel.localizedNodeName($0.name) } ?? lm.s(L.mapPendingLocation))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: "#6B5B4D"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 112, alignment: .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, 14)
            .padding(.leading, 16)
            .allowsHitTesting(false)
        }
    }

    private var floorSelector: some View {
        Group {
            if isCompact {
                VStack(spacing: 6) {
                    floorSelectorButtons
                }
                .padding(.leading, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 8) {
                    floorSelectorButtons
                }
                .padding(.top, 18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }

    @ViewBuilder
    private var floorSelectorButtons: some View {
        ForEach(MuseumNavFloor.allCases) { floor in
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.selectFloor(floor)
                }
            } label: {
                Text(isCompact ? floor.shortTitle : "\(lm.s(L.mapFloorLevel)) \(floor.rawValue)")
                    .font(.system(size: isCompact ? 10 : 12, weight: .semibold))
                    .foregroundStyle(viewModel.selectedFloor == floor ? .white : Color(hex: "#4F4339"))
                    .frame(minWidth: isCompact ? 34 : 0)
                    .padding(.horizontal, isCompact ? 0 : 12)
                    .padding(.vertical, isCompact ? 7 : 8)
                    .background(
                        viewModel.selectedFloor == floor
                            ? Color.h3Orange
                            : Color.white.opacity(0.82)
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func interactiveMap(in size: CGSize) -> some View {
        ZStack {
            interactiveMapBackground(in: size)
                .zIndex(1)

            interactiveNodeLayer(in: size)
                .zIndex(2)
        }
        .simultaneousGesture(isCompact ? nil : doubleTapResetGesture(in: size))
        .simultaneousGesture((isCompact || !nodePlacementToolsEnabled) ? nil : mapCoordinateTapGesture(in: size))
        .clipped()
    }

    private func interactiveMapBackground(in size: CGSize) -> some View {
        ZStack {
            floorPlanBackground(in: size)
            gridOverlay
            pathOverlay(in: size)
        }
        .scaleEffect(displayScale, anchor: .center)
        .offset(displayOffset)
        .contentShape(Rectangle())
        .gesture(isCompact ? nil : dragGesture)
        .simultaneousGesture(isCompact ? nil : magnificationGesture)
    }

    private func floorPlanBackground(in size: CGSize) -> some View {
        let metrics = floorPlanMetrics(in: size)

        return Group {
            if UIImage(named: viewModel.selectedFloor.assetName) != nil {
                Image(viewModel.selectedFloor.assetName)
                    .resizable()
                    .frame(width: metrics.imageFrame.width, height: metrics.imageFrame.height)
                    .overlay {
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.10),
                                Color.black.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
            } else {
                museumFloorPlaceholder
            }
        }
        .position(x: metrics.imageFrame.midX, y: metrics.imageFrame.midY)
    }

    private var museumFloorPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#F7F1E8"), Color(hex: "#E6D7C4")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: 28)
                .fill(Color(hex: "#C6B29B").opacity(0.25))
                .padding(22)

            VStack(spacing: 10) {
                Image(systemName: "map.fill")
                    .font(.system(size: isCompact ? 18 : 26, weight: .bold))
                    .foregroundStyle(Color(hex: "#8C745B"))

                Text("\(lm.s(L.mapFloorLevel)) \(viewModel.selectedFloor.rawValue)")
                    .font(.system(size: isCompact ? 12 : 16, weight: .bold))
                    .foregroundStyle(Color(hex: "#6E5A48"))

                Text("Agrega el asset \(viewModel.selectedFloor.assetName)")
                    .font(.system(size: isCompact ? 9 : 11, weight: .medium))
                    .foregroundStyle(Color(hex: "#8C745B"))
            }
            .multilineTextAlignment(.center)
            .padding(20)
        }
    }

    private func interactiveNodeLayer(in size: CGSize) -> some View {
        ZStack {
            ForEach(viewModel.displayedNodes) { node in
                nodeMarker(node, in: size)
            }

            if let destination = viewModel.selectedDestinationNodeOnSelectedFloor {
                destinationMarker(destination, in: size)
            }

            if let current = viewModel.currentNodeOnSelectedFloor {
                currentMarker(current, in: size)
            }
        }
        .scaleEffect(displayScale, anchor: .center)
        .offset(displayOffset)
        .allowsHitTesting(true)
    }

    @ViewBuilder
    private var settingsControls: some View {
        if !isCompact {
            VStack(alignment: .trailing, spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSettingsExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: isCompact ? 13 : 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: isCompact ? 34 : 42, height: isCompact ? 34 : 42)
                        .background(isSettingsExpanded ? Color.h3Orange : Color.black.opacity(0.72))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                if isSettingsExpanded {
                    if nodePlacementToolsEnabled {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.showFillerNodes.toggle()
                            }
                        } label: {
                            Image(systemName: "smallcircle.filled.circle")
                                .font(.system(size: isCompact ? 13 : 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: isCompact ? 34 : 42, height: isCompact ? 34 : 42)
                                .background(viewModel.showFillerNodes ? Color.h3Orange : Color.black.opacity(0.72))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Mostrar nodos filler")
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.isWheelchairModeEnabled.toggle()
                        }
                    } label: {
                        Image(systemName: "figure.roll")
                            .font(.system(size: isCompact ? 13 : 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: isCompact ? 34 : 42, height: isCompact ? 34 : 42)
                            .background(viewModel.isWheelchairModeEnabled ? Color.h3Orange : Color.black.opacity(0.72))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(lm.s(L.mapWheelchairMode))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(isCompact ? 10 : 18)
        }
    }

    private func recenterFloatingButton(in size: CGSize) -> some View {
        let floatingHeight = min(size.height * 0.26, 190)
        let bottomMargin: CGFloat = 110

        return Button {
            if viewModel.currentNodeOnSelectedFloor != nil {
                centerOnCurrentNode(in: size)
            } else {
                resetMapView()
            }
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Color.black.opacity(0.72))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.trailing, 18)
        .padding(.bottom, bottomMargin + floatingHeight + 18)
        .zIndex(5)
    }

    @ViewBuilder
    private var gridOverlay: some View {
        if !isCompact {
            GeometryReader { proxy in
                Path { path in
                    let columns = 6
                    let rows = 6
                    let columnWidth = proxy.size.width / CGFloat(columns)
                    let rowHeight = proxy.size.height / CGFloat(rows)

                    for column in 1..<columns {
                        let x = CGFloat(column) * columnWidth
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                    }

                    for row in 1..<rows {
                        let y = CGFloat(row) * rowHeight
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                    }
                }
                .stroke(Color(hex: "#BCA78B").opacity(0.35), lineWidth: 1)
            }
        }
    }

    private func pathOverlay(in size: CGSize) -> some View {
        Path { path in
            let routeSegments = viewModel.routePathSegmentsOnSelectedFloor

            for routePath in routeSegments {
                guard let first = routePath.first else { continue }

                path.move(to: scaledPoint(for: first, in: size))

                for node in routePath.dropFirst() {
                    path.addLine(to: scaledPoint(for: node, in: size))
                }
            }
        }
        .stroke(
            Color(hex: "#F05A28"),
            style: StrokeStyle(lineWidth: isCompact ? 3 : 5, lineCap: .round, dash: [10, 8])
        )
        .opacity(viewModel.routePathSegmentsOnSelectedFloor.isEmpty ? 0 : 1)
    }

    private func nodeMarker(_ node: MuseumNavMapNode, in size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(Color.clear)
                .frame(width: isCompact ? 36 : 58, height: isCompact ? 36 : 58)

            Circle()
                .fill(nodeColor(for: node).opacity(isCompact ? 0.78 : 0.95))
                .frame(width: markerSize(for: node), height: markerSize(for: node))

            if let icon = nodeIcon(for: node) {
                Image(systemName: icon)
                    .font(.system(size: iconSize(for: node), weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .contentShape(Circle())
        .onTapGesture {
            guard !isCompact else { return }
            guard node.nodeType != "filler" || (nodePlacementToolsEnabled && viewModel.showFillerNodes) else { return }
            viewModel.selectNode(node)
            centerOnNode(node, in: size)
        }
        .position(scaledPoint(for: node, in: size))
        .zIndex(3)
    }

    private func nodeDetailsBubble(for node: MuseumNavMapNode, in size: CGSize) -> some View {
        let point = displayedPoint(for: node, in: size)
        let bubbleWidth = min(size.width * 0.62, 250)
        let x = min(max(point.x, bubbleWidth / 2 + 16), size.width - (bubbleWidth / 2) - 16)
        let y = max(90, point.y - 110)

        return VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Image(viewModel.selectedNodeDetails?.image ?? "horno3")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.selectedNodeDetails?.name ?? viewModel.localizedNodeName(node.name))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color(hex: "#201A16"))

                        Text(viewModel.selectedNodeDetails?.description ?? lm.s(L.mapLoadingDetails))
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#5E5146"))
                            .lineLimit(4)

                        if nodePlacementToolsEnabled {
                            Text(debugCoordinateText(for: node))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color(hex: "#F05A28"))
                                .textSelection(.enabled)
                        }
                    }

                    Spacer(minLength: 0)

                    Button {
                        viewModel.clearSelectedNode()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: "#5E5146"))
                            .frame(width: 24, height: 24)
                            .background(Color.black.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    viewModel.selectDestinationNode(node)
                } label: {
                    Text(lm.s(L.mapGoHere))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(viewModel.selectedNodeIsCurrentDestination ? Color.gray.opacity(0.6) : Color.h3Orange)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.selectedNodeIsCurrentDestination)
            }
            .padding(14)
            .frame(width: bubbleWidth)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22))

            Triangle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 18, height: 10)
                .rotationEffect(.degrees(180))
        }
        .position(x: x, y: y)
        .zIndex(10)
        .shadow(color: .black.opacity(0.14), radius: 18, y: 10)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.92, anchor: .bottom).combined(with: .opacity),
            removal: .scale(scale: 0.96, anchor: .bottom).combined(with: .opacity)
        ))
    }

    private func mapCoordinateBubble(_ coordinate: DebugMapCoordinate, in size: CGSize) -> some View {
        let bubbleWidth: CGFloat = 156
        let x = min(max(coordinate.point.x, bubbleWidth / 2 + 12), size.width - (bubbleWidth / 2) - 12)
        let y = min(max(coordinate.point.y - 34, 74), size.height - 130)

        return Text(debugCoordinateText(x: coordinate.x, y: coordinate.y, floor: coordinate.floor))
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white)
            .textSelection(.enabled)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(width: bubbleWidth)
            .background(Color.black.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .position(x: x, y: y)
            .zIndex(11)
            .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
    }

    private func destinationMarker(_ node: MuseumNavMapNode, in size: CGSize) -> some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "#F05A28"), lineWidth: isCompact ? 2 : 3)
                .frame(width: isCompact ? 28 : 42, height: isCompact ? 28 : 42)

            Circle()
                .fill(Color(hex: "#F05A28"))
                .frame(width: isCompact ? 12 : 18, height: isCompact ? 12 : 18)
        }
        .position(scaledPoint(for: node, in: size))
    }

    private func currentMarker(_ node: MuseumNavMapNode, in size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#30D158").opacity(0.25))
                .frame(width: isCompact ? 34 : 48, height: isCompact ? 34 : 48)

            Circle()
                .fill(Color(hex: "#30D158"))
                .frame(width: isCompact ? 18 : 24, height: isCompact ? 18 : 24)
        }
        .position(scaledPoint(for: node, in: size))
    }

    private func debugCoordinateText(for node: MuseumNavMapNode) -> String {
        "ID \(node.id) · \(debugCoordinateText(x: node.x, y: node.y, floor: node.floor))"
    }

    private func debugCoordinateText(x: CGFloat, y: CGFloat, floor: MuseumNavFloor) -> String {
        let x = String(format: "%.1f", Double(x))
        let y = String(format: "%.1f", Double(y))
        return "\(floor.shortTitle) · x \(x) · y \(y)"
    }

    private func scaledPoint(for node: MuseumNavMapNode, in size: CGSize) -> CGPoint {
        let metrics = floorPlanMetrics(in: size)
        let nodeOffset = activeRenderedNodeOffset(for: metrics)
        return CGPoint(
            x: metrics.viewportRect.minX + ((node.x - metrics.sourceRect.minX) * metrics.scale) + nodeOffset.width,
            y: metrics.viewportRect.minY + ((metrics.sourceRect.maxY - node.y) * metrics.scale) + nodeOffset.height
        )
    }

    private func mapCoordinateTapGesture(in size: CGSize) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                let coordinate = mapCoordinate(fromDisplayedPoint: value.location, in: size)
                debugMapCoordinate = DebugMapCoordinate(
                    point: value.location,
                    x: coordinate.x,
                    y: coordinate.y,
                    floor: viewModel.selectedFloor
                )
            }
    }

    private func mapCoordinate(fromDisplayedPoint point: CGPoint, in size: CGSize) -> CGPoint {
        let metrics = floorPlanMetrics(in: size)
        let nodeOffset = activeRenderedNodeOffset(for: metrics)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let unoffsetPoint = CGPoint(
            x: point.x - displayOffset.width,
            y: point.y - displayOffset.height
        )
        let unscaledPoint = CGPoint(
            x: center.x + ((unoffsetPoint.x - center.x) / displayScale),
            y: center.y + ((unoffsetPoint.y - center.y) / displayScale)
        )

        return CGPoint(
            x: metrics.sourceRect.minX + ((unscaledPoint.x - metrics.viewportRect.minX - nodeOffset.width) / metrics.scale),
            y: metrics.sourceRect.maxY - ((unscaledPoint.y - metrics.viewportRect.minY - nodeOffset.height) / metrics.scale)
        )
    }

    private func activeRenderedNodeOffset(for metrics: FloorPlanMetrics) -> CGSize {
        guard isCompact else { return renderedNodeOffset }
        return CGSize(
            width: renderedNodeOffset.width * metrics.scale,
            height: renderedNodeOffset.height * metrics.scale
        )
    }

    private func floorPlanMetrics(in size: CGSize) -> FloorPlanMetrics {
        let viewportRect = mapViewportRect(in: size)
        let sourceRect = viewModel.selectedFloor.focusRect
        let scale = max(viewportRect.width / sourceRect.width, viewportRect.height / sourceRect.height)
        let canvasSize = viewModel.selectedFloor.canvasSize
        let imageSize = CGSize(width: canvasSize.width * scale, height: canvasSize.height * scale)
        let imageOrigin = CGPoint(
            x: viewportRect.minX - (sourceRect.minX * scale),
            y: viewportRect.minY - (sourceRect.minY * scale)
        )

        return FloorPlanMetrics(
            viewportRect: viewportRect,
            sourceRect: sourceRect,
            scale: scale,
            imageFrame: CGRect(origin: imageOrigin, size: imageSize)
        )
    }

    private func mapViewportRect(in size: CGSize) -> CGRect {
        let isLandscape = size.width > size.height
        let horizontalInset: CGFloat = isCompact ? 10 : (isLandscape ? 0 : 0)
        let verticalInset: CGFloat = isCompact ? 10 : (isLandscape ? 0 : 0)
        let availableWidth = max(size.width - (horizontalInset * 2), 1)
        let availableHeight = max(size.height - (verticalInset * 2), 1)
        return CGRect(x: horizontalInset, y: verticalInset, width: availableWidth, height: availableHeight)
    }

    private var displayScale: CGFloat {
        zoomScale * pinchScale
    }

    private var displayOffset: CGSize {
        CGSize(
            width: contentOffset.width + dragTranslation.width,
            height: contentOffset.height + dragTranslation.height
        )
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                dragTranslation = value.translation
            }
            .onEnded { value in
                contentOffset.width += value.translation.width
                contentOffset.height += value.translation.height
                dragTranslation = .zero
            }
    }

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                pinchScale = value.magnification
            }
            .onEnded { value in
                zoomScale = min(max(zoomScale * value.magnification, 1), 4)
                pinchScale = 1
            }
    }

    private func centerOnCurrentNode(in size: CGSize) {
        guard let currentNode = viewModel.currentNodeOnSelectedFloor else { return }

        let point = scaledPoint(for: currentNode, in: size)

        withAnimation(.easeInOut(duration: 0.22)) {
            zoomScale = 1
            pinchScale = 1
            contentOffset = CGSize(
                width: (size.width / 2) - point.x,
                height: (size.height / 2) - point.y
            )
            dragTranslation = .zero
        }
    }

    private func resetMapView() {
        withAnimation(.easeInOut(duration: 0.22)) {
            zoomScale = 1
            pinchScale = 1
            contentOffset = .zero
            dragTranslation = .zero
        }
    }

    private func centerOnSelectedDestination(in size: CGSize) {
        guard let destinationNode = viewModel.selectedDestinationNodeOnSelectedFloor else { return }

        let point = scaledPoint(for: destinationNode, in: size)

        withAnimation(.easeInOut(duration: 0.22)) {
            contentOffset = CGSize(
                width: (size.width / 2) - point.x,
                height: (size.height / 2) - point.y
            )
            dragTranslation = .zero
        }
    }

    private func centerOnNode(_ node: MuseumNavMapNode, in size: CGSize) {
        let point = scaledPoint(for: node, in: size)

        withAnimation(.interpolatingSpring(stiffness: 140, damping: 24)) {
            contentOffset = CGSize(
                width: (size.width / 2) - point.x,
                height: (size.height / 2) - point.y
            )
            dragTranslation = .zero
        }
    }

    private func displayedPoint(for node: MuseumNavMapNode, in size: CGSize) -> CGPoint {
        let original = scaledPoint(for: node, in: size)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let scaled = CGPoint(
            x: center.x + ((original.x - center.x) * displayScale),
            y: center.y + ((original.y - center.y) * displayScale)
        )

        return CGPoint(
            x: scaled.x + displayOffset.width,
            y: scaled.y + displayOffset.height
        )
    }

    private func nodeColor(for node: MuseumNavMapNode) -> Color {
        switch node.nodeType {
        case "filler":
            return Color(hex: "#8E8E93")
        case "stairs":
            return Color(hex: "#AF52DE")
        case "exit":
            return Color(hex: "#0A84FF")
        case "accessibility":
            return Color(hex: "#34C759")
        case "special":
            return Color(hex: "#FFB340")
        case "bathroom":
            return Color(hex: "#5AC8FA")
        case "food":
            return Color(hex: "#FF9F0A")
        case "shop":
            return Color(hex: "#FF375F")
        default:
            return Color(hex: "#6A5846")
        }
    }

    private func nodeIcon(for node: MuseumNavMapNode) -> String? {
        switch node.nodeType {
        case "filler":
            return nil
        case "stairs":
            return "stairs"
        case "special":
            return "star.fill"
        case "exit":
            return "figure.walk.motion"
        case "accessibility":
            return "figure.roll"
        case "bathroom":
            return "figure.stand"
        case "food":
            return "fork.knife"
        case "shop":
            return "bag.fill"
        default:
            return nil
        }
    }

    private func markerSize(for node: MuseumNavMapNode) -> CGFloat {
        if node.nodeType == "filler" {
            return isCompact ? 10 : 14
        }
        return isCompact ? 23 : 36
    }

    private func iconSize(for node: MuseumNavMapNode) -> CGFloat {
        isCompact ? 12 : 17
    }
    
    private func doubleTapResetGesture(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                if viewModel.currentNodeOnSelectedFloor != nil {
                    centerOnCurrentNode(in: size)
                } else {
                    resetMapView()
                }
            }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    MuseumNavMiniMapView(viewModel: MuseumNavViewModel())
        .frame(width: 320, height: 320)
        .padding()
        .background(Color.black)
}
