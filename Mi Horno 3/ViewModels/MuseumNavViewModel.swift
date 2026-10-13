import Foundation
import CoreGraphics
import Observation

@MainActor
@Observable
final class MuseumNavViewModel {
    let camera = CameraManager()
    private let lm = LocalizationManager.shared
    private let dummyUserNode = MuseumNavMapNode(
        id: -999,
        name: L.mapNodeUsuarioDummy,
        x: 967.7,
        y: 400,
        floor: .level2,
        qr: nil,
        nodeType: "user"
    )
    private let graphEdges: [MuseumNavGraphEdge] = [
        // Nivel 1
        .init(from: 1, to: 101), .init(from: 101, to: 102), .init(from: 102, to: 103),
        .init(from: 103, to: 104), .init(from: 104, to: 105), .init(from: 105, to: 106),
        .init(from: 106, to: 107), .init(from: 107, to: 108), .init(from: 108, to: 109),
        .init(from: 109, to: 110), .init(from: 103, to: 112), .init(from: 112, to: 110),
        .init(from: 102, to: 111), .init(from: 111, to: 105),
        .init(from: 2, to: 104), .init(from: 2, to: 103),
        .init(from: 3, to: 106), .init(from: 4, to: 111),
        .init(from: 5, to: 102), .init(from: 6, to: 110),
        .init(from: 7, to: 110), .init(from: 7, to: 112),
        .init(from: 8, to: 108), .init(from: 9, to: 109),
        .init(from: 10, to: 105), .init(from: 11, to: 107),
        .init(from: 12, to: 104), .init(from: 12, to: 108),
        .init(from: 13, to: 108),
        .init(from: 15, to: 102), .init(from: 15, to: 112),
        .init(from: 7, to: 112), .init(from: 33, to: 112),

        // Nivel 2
        .init(from: 16, to: 201), .init(from: 201, to: 202), .init(from: 202, to: 203),
        .init(from: 203, to: 205), .init(from: 205, to: 206),
        .init(from: 205, to: 207), .init(from: 17, to: 202), .init(from: 18, to: 202),
        .init(from: 19, to: 203), .init(from: 19, to: 205), .init(from: 20, to: 205), .init(from: 21, to: 206),
        .init(from: 22, to: 207), .init(from: 23, to: 203), .init(from: 24, to: 203),
        .init(from: 23, to: 205),
        .init(from: 34, to: 203), .init(from: 34, to: 205),

        // Nivel 3
        .init(from: 31, to: 301), .init(from: 301, to: 302), .init(from: 302, to: 303),
        .init(from: 303, to: 304), .init(from: 304, to: 305), .init(from: 26, to: 302),
        .init(from: 27, to: 303), .init(from: 28, to: 304), .init(from: 29, to: 304),
        .init(from: 30, to: 305), .init(from: 32, to: 305),
        .init(from: 35, to: 305), .init(from: 35, to: 304),

        // Conectores entre pisos
        .init(from: 7, to: 23, kind: .elevator), .init(from: 23, to: 31, kind: .elevator),
        .init(from: 33, to: 34, kind: .stairs), .init(from: 34, to: 35, kind: .stairs)
    ]

    var nodes: [MuseumNavMapNode] = [
        // Nivel 1
        MuseumNavMapNode(id: 1, name: L.mapNodeEntradaPrincipal, x: 180, y: 360, floor: .level1, qr: "QR_ENTRADA", nodeType: "entry"),
        MuseumNavMapNode(id: 2, name: L.mapNodeLobby, x: 600, y: 350, floor: .level1, qr: "QR_CENTRAL", nodeType: "hall"),
        MuseumNavMapNode(id: 3, name: L.mapNodeBanos, x: 480, y: 851, floor: .level1, qr: "QR_BANO1", nodeType: "bathroom"),
        MuseumNavMapNode(id: 4, name: L.mapNodeTiendaDeSouvenirs, x: 522, y: 433, floor: .level1, qr: "QR_RECUERDOS", nodeType: "shop"),
        MuseumNavMapNode(id: 5, name: L.mapNodeTaquillaEInformacion, x: 1279, y: 106, floor: .level1, nodeType: "special"),
        MuseumNavMapNode(id: 6, name: L.mapNodeSnackH3, x: 1070, y: 160, floor: .level1, qr: "QR_SNACKS", nodeType: "food"),
        MuseumNavMapNode(id: 7, name: L.mapNodeElevadorInclinado, x: 960, y: 184, floor: .level1, nodeType: "accessibility"),
        MuseumNavMapNode(id: 8, name: L.mapNodePatioDeDemostraciones, x: 1157, y: 550, floor: .level1, nodeType: "special"),
        MuseumNavMapNode(id: 9, name: L.mapNodePaseoPorLasEstufas, x: 1300, y: 306, floor: .level1, nodeType: "special"),
        MuseumNavMapNode(id: 10, name: L.mapNodeGaleriaDelAcero, x: 635, y: 690, floor: .level1, nodeType: "special"),
        MuseumNavMapNode(id: 11, name: L.mapNodeGaleriaDeLaHistoria, x: 727, y: 670, floor: .level1, nodeType: "special"),
        MuseumNavMapNode(id: 12, name: L.mapNodeHornoAlto, x: 865, y: 500, floor: .level1, nodeType: "special"),
        MuseumNavMapNode(id: 13, name: L.mapNodeExplanadaEstufas, x: 1205.1, y: 757.3, floor: .level1, nodeType: "special"),


        // Nivel 2
        MuseumNavMapNode(id: 16, name: L.mapNodeTerraza, x: 300, y: 400.0, floor: .level2, nodeType: "special"),
        MuseumNavMapNode(id: 17, name: L.mapNodeShowHorno, x: 750, y: 700, floor: .level2, nodeType: "special"),
        MuseumNavMapNode(id: 18, name: L.mapNodeHornoAltoNivel2, x: 750, y: 520, floor: .level2, nodeType: "special"),
        MuseumNavMapNode(id: 19, name: L.mapNodeH3PlanetaTierra, x: 1170, y: 650, floor: .level2, nodeType: "special"),
        MuseumNavMapNode(id: 20, name: L.mapNodePaseoPorLasEstufasNivel2, x: 1597.4, y: 300, floor: .level2, nodeType: "special"),
        MuseumNavMapNode(id: 21, name: L.mapNodeRestauranteElLingote, x: 1566.7, y: 100, floor: .level2, nodeType: "food"),
        MuseumNavMapNode(id: 22, name: L.mapNodeSalidaAccesoDerechoNivel2, x: 1810, y: 590, floor: .level2, nodeType: "exit"),
        MuseumNavMapNode(id: 24, name: L.mapNodeBanosNivel2, x: 960.0, y: 200, floor: .level2, nodeType: "bathroom"),

        // Accesibilidad nivel 2
        MuseumNavMapNode(id: 23, name: L.mapNodeElevadorInclinadoNivel2, x: 1210, y: 200, floor: .level2, nodeType: "accessibility"),

        // Nivel 3
        MuseumNavMapNode(id: 26, name: L.mapNodeBocaDelHornoAlto, x: 610, y: 575, floor: .level3, nodeType: "special"),
        MuseumNavMapNode(id: 27, name: L.mapNodeMiradorCentral, x: 610, y: 680, floor: .level3, nodeType: "special"),
        MuseumNavMapNode(id: 28, name: L.mapNodeMiradorEste, x: 1335, y: 430, floor: .level3, nodeType: "special"),
        MuseumNavMapNode(id: 29, name: L.mapNodeMiradorSur, x: 1090, y: 430, floor: .level3, nodeType: "special"),

        // Accesibilidad nivel 3
        MuseumNavMapNode(id: 31, name: L.mapNodeElevadorInclinadoNivel3, x: 615, y: 280, floor: .level3, nodeType: "accessibility"),

        //Escaleras
        MuseumNavMapNode(id: 33, name: L.mapNodeEscalerasNivel1, x: 650, y: 465, floor: .level1, nodeType: "stairs"),
        MuseumNavMapNode(id: 34, name: L.mapNodeEscalerasNivel2, x: 530, y: 280, floor: .level2, nodeType: "stairs"),
        MuseumNavMapNode(id: 35, name: L.mapNodeEscalerasNivel3, x: 1645, y: 560, floor: .level3, nodeType: "stairs"),

        // Fillers nivel 1
        MuseumNavMapNode(id: 101, name: "Filler N1 Entrada", x: 230, y: 356, floor: .level1, nodeType: "filler"),
        MuseumNavMapNode(id: 102, name: "Filler N1 Lobby sur", x: 637, y: 346, floor: .level1, nodeType: "filler"),
        MuseumNavMapNode(id: 103, name: "Filler N1 Lobby centro", x: 900, y: 315, floor: .level1, nodeType: "filler"),
        MuseumNavMapNode(id: 104, name: "Filler N1 Horno sur", x: 670, y: 442, floor: .level1, nodeType: "filler"),
        MuseumNavMapNode(id: 105, name: "Filler N1 Acero", x: 670, y: 670, floor: .level1, nodeType: "filler"),
        MuseumNavMapNode(id: 106, name: "Filler N1 Banos", x: 471, y: 810, floor: .level1, nodeType: "filler"),
        MuseumNavMapNode(id: 107, name: "Filler N1 Historia", x: 583.0, y: 709.8, floor: .level1, nodeType: "filler"),
        MuseumNavMapNode(id: 108, name: "Filler N1 Este alto", x: 700, y: 633, floor: .level1, nodeType: "filler"),
        MuseumNavMapNode(id: 109, name: "Filler N1 Estufas medio", x: 1450, y: 305, floor: .level1, nodeType: "filler"),
        MuseumNavMapNode(id: 110, name: "Filler N1 Estufas bajo", x: 1256, y: 330, floor: .level1, nodeType: "filler"),
        MuseumNavMapNode(id: 111, name: "Filler N1 Souvenirs", x: 562, y: 411, floor: .level1, nodeType: "filler"),
        MuseumNavMapNode(id: 112, name: "Filler N1 Lobby este", x: 1055, y: 372, floor: .level1, nodeType: "filler"),

        // Fillers nivel 2
        MuseumNavMapNode(id: 201, name: "Filler N2 Terraza", x: 514.6, y: 600.0, floor: .level2, nodeType: "filler"),
        MuseumNavMapNode(id: 202, name: "Filler N2 Show", x: 870, y: 300, floor: .level2, nodeType: "filler"),
        MuseumNavMapNode(id: 203, name: "Filler N2 Centro", x: 1144.3, y: 300, floor: .level2, nodeType: "filler"),
        MuseumNavMapNode(id: 205, name: "Filler N2 Paseo", x: 1400.4, y: 300, floor: .level2, nodeType: "filler"),
        MuseumNavMapNode(id: 206, name: "Filler N2 Restaurante", x: 1574.4, y: 790.6, floor: .level2, nodeType: "filler"),
        MuseumNavMapNode(id: 207, name: "Filler N2 Salida", x: 1781.8, y: 393.1, floor: .level2, nodeType: "filler"),

        // Fillers nivel 3
        MuseumNavMapNode(id: 301, name: "Filler N3 Elevador", x: 613, y: 325, floor: .level3, nodeType: "filler"),
        MuseumNavMapNode(id: 302, name: "Filler N3 Centro sur", x: 710, y: 515, floor: .level3, nodeType: "filler"),
        MuseumNavMapNode(id: 303, name: "Filler N3 Centro", x: 880, y: 490, floor: .level3, nodeType: "filler"),
        MuseumNavMapNode(id: 304, name: "Filler N3 Pasarela", x: 1642, y: 474, floor: .level3, nodeType: "filler"),
        MuseumNavMapNode(id: 305, name: "Filler N3 Salida", x: 1642, y:525, floor: .level3, nodeType: "filler")
    ]

    var currentNode: MuseumNavMapNode?
    var selectedNode: MuseumNavMapNode?
    var selectedNodeDetails: MuseumNavNodeDetails?
    var selectedRouteIndex = 0
    var selectedDestinationIndex = 0
    private var selectedDestinationID: Int?
    var isWheelchairModeEnabled = false

    // Herramientas utilizadas para acomodar los nodos.
    // Se mantiene la bandera para depurar fillers, pero la UI pública la deja oculta.
    var showFillerNodes = false
    var lastScannedQR: String?
    var lastScannedPayload: String?
    var isFetchingNode = false
    var isFetchingNodeDetails = false
    var lastErrorMessage: String?
    var selectedFloor: MuseumNavFloor = .level1
    private var selectedNodeDetailsRequestID = UUID()
    private var lastUploadedLocationSignature: String?

    let routes = [
        L.mapRouteGeneral,
        L.mapRouteSculptures,
        L.mapRoutePaintings
    ]

    init() {
        currentNode = dummyUserNode
        selectedFloor = dummyUserNode.floor

        camera.onQRCodeDetected = { [weak self] qr in
            Task { @MainActor in
                await self?.handleDetectedQRCode(qr)
            }
        }
        camera.onError = { [weak self] error in
            Task { @MainActor in
                self?.handleCameraError(error)
            }
        }
    }

    var destinations: [String] {
        nodes
            .filter {
                $0.floor == selectedFloor
                && ($0.nodeType == "bathroom"
                || $0.nodeType == "food"
                || $0.nodeType == "shop"
                || $0.nodeType == "special"
                || $0.nodeType == "exit"
                || $0.nodeType == "accessibility")
            }
            .map(\.name)
    }

    var displayedNodes: [MuseumNavMapNode] {
        nodes.filter { node in
            guard node.floor == selectedFloor else { return false }
            guard node.nodeType != "user" else { return false }
            guard node.nodeType != "filler" else { return showFillerNodes }
            return true
        }
    }

    var routePath: [MuseumNavMapNode] {
        guard let currentNode,
              let destination = selectedDestinationNode else { return [] }
        guard currentNode.id != destination.id else { return [currentNode] }

        let graphNodes = nodes.filter { $0.nodeType != "user" }
        let nodeByID = Dictionary(uniqueKeysWithValues: graphNodes.map { ($0.id, $0) })
        let adjacency = buildAdjacency()
        let waypointNodes = selectedRouteWaypoints(
            from: currentNode,
            to: destination,
            nodeByID: nodeByID
        )
        let checkpoints = [currentNode] + waypointNodes + [destination]
        var resolvedPath: [MuseumNavMapNode] = []

        for segmentIndex in 0..<(checkpoints.count - 1) {
            let start = checkpoints[segmentIndex]
            let end = checkpoints[segmentIndex + 1]

            guard let startAnchor = nearestRoutableNode(to: start, among: graphNodes, adjacency: adjacency),
                  let endAnchor = nearestRoutableNode(to: end, among: graphNodes, adjacency: adjacency),
                  let graphPath = shortestPath(from: startAnchor.id, to: endAnchor.id, nodeByID: nodeByID, adjacency: adjacency) else {
                return resolvedPath.isEmpty ? [currentNode, destination] : deduplicated(path: resolvedPath + [destination])
            }

            var segmentPath = graphPath.compactMap { nodeByID[$0] }

            if segmentPath.first?.id != start.id {
                segmentPath.insert(start, at: 0)
            }

            if segmentPath.last?.id != end.id {
                segmentPath.append(end)
            }

            if !resolvedPath.isEmpty, resolvedPath.last?.id == segmentPath.first?.id {
                segmentPath.removeFirst()
            }

            resolvedPath.append(contentsOf: segmentPath)
        }

        return deduplicated(path: resolvedPath)
    }

    var routePathSegmentsOnSelectedFloor: [[MuseumNavMapNode]] {
        var segments: [[MuseumNavMapNode]] = []
        var currentSegment: [MuseumNavMapNode] = []

        for node in routePath {
            if node.floor == selectedFloor {
                currentSegment.append(node)
            } else if !currentSegment.isEmpty {
                segments.append(currentSegment)
                currentSegment = []
            }
        }

        if !currentSegment.isEmpty {
            segments.append(currentSegment)
        }

        return segments
    }

    var routePathOnSelectedFloor: [MuseumNavMapNode] {
        routePathSegmentsOnSelectedFloor.flatMap { $0 }
    }

    var prioritizedNodeTypes: [String] {
        isWheelchairModeEnabled ? ["accessibility", "entry", "hall", "exit"] : []
    }

    var selectedRouteName: String {
        guard !routes.isEmpty else { return lm.s(L.mapNoRoutes) }
        return routes[clampedRouteIndex]
    }

    var selectedDestinationName: String {
        if let selectedDestinationNode {
            return selectedDestinationNode.name
        }

        return destinationNodeForCurrentIndex()?.name ?? lm.s(L.mapNoDestinations)
    }

    var selectedDestinationNode: MuseumNavMapNode? {
        if let selectedDestinationID,
           let selectedNode = nodes.first(where: { $0.id == selectedDestinationID }) {
            return selectedNode
        }

        return nil
    }

    var currentNodeOnSelectedFloor: MuseumNavMapNode? {
        guard currentNode?.floor == selectedFloor else { return nil }
        return currentNode
    }

    var selectedDestinationNodeOnSelectedFloor: MuseumNavMapNode? {
        guard selectedDestinationNode?.floor == selectedFloor else { return nil }
        return selectedDestinationNode
    }

    var scanStatusText: String {
        if let lastErrorMessage {
            return lastErrorMessage
        }
        if let lastScannedPayload {
            return "\(lm.s(L.mapQrDetected)): \(lastScannedPayload)"
        }
        if let currentNode {
            return "\(lm.s(L.mapCurrentPosition)): \(localizedNodeName(currentNode.name))"
        }
        if isFetchingNode {
            return "\(lm.s(L.mapScanTitle))..."
        }
        return lm.s(L.mapAlignQr)
    }

    var isCameraErrorActive: Bool {
        lastErrorMessage == lm.s(L.mapCameraUnavailable)
        || lastErrorMessage == lm.s(L.mapCameraInputError)
    }

    var selectedNodeIsCurrentDestination: Bool {
        guard let selectedNode else { return false }
        return selectedNode.id == selectedDestinationNode?.id
    }

    func startCamera() {
        camera.start()
    }

    func stopCamera() {
        camera.stop()
    }

    func selectFloor(_ floor: MuseumNavFloor) {
        selectedFloor = floor
        normalizeSelectedDestinationIndex()
    }

    func selectDestinationAtCurrentIndex() {
        selectedDestinationID = destinationNodeForCurrentIndex()?.id
    }

    func selectNode(_ node: MuseumNavMapNode) {
        guard node.nodeType != "filler" || showFillerNodes else { return }
        selectedNode = node
        selectedNodeDetails = localNodeDetails(for: node)
        selectedNodeDetailsRequestID = UUID()
        isFetchingNodeDetails = false
    }

    func clearSelectedNode() {
        selectedNodeDetailsRequestID = UUID()
        selectedNode = nil
        selectedNodeDetails = nil
        isFetchingNodeDetails = false
    }

    func updatePosition(qr: String) {
        currentNode = nodes.first(where: { $0.qr == qr })
        if currentNode == nil {
            currentNode = MuseumNavMapNode(id: -1, name: L.mapNodeDesconocido, x: 0, y: 0, floor: selectedFloor, qr: qr, nodeType: nil)
        } else if let currentNode {
            selectFloor(currentNode.floor)
        }
    }

    func handleDetectedQRCode(_ qr: String) async {
        let sanitizedQR = qr.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedQR.isEmpty else { return }
        guard sanitizedQR != lastScannedQR || currentNode == nil else { return }
        guard !isFetchingNode else { return }

        if let localNode = nodes.first(where: { $0.qr == sanitizedQR }) {
            lastErrorMessage = nil
            lastScannedQR = sanitizedQR
            lastScannedPayload = sanitizedQR
            currentNode = localNode
            selectFloor(localNode.floor)
            return
        }

        lastErrorMessage = nil
        lastScannedQR = sanitizedQR
        lastScannedPayload = sanitizedQR
        updatePosition(qr: sanitizedQR)
        isFetchingNode = false
    }

    func selectDestinationNode(_ node: MuseumNavMapNode) {
        guard node.nodeType != "filler" else { return }
        if currentNode == nil {
            selectFloor(node.floor)
        }
        if let index = destinations.firstIndex(of: node.name) {
            selectedDestinationIndex = index
        }
        selectedDestinationID = node.id
        selectNode(node)
    }

    func uploadCurrentUserLocationIfNeeded(userID: Int) {
        guard userID > 0, let currentNode else { return }

        let mapNodeID = currentNode.id > 0 ? currentNode.id : nil
        let hasCoordinates = currentNode.x != 0 || currentNode.y != 0
        guard mapNodeID != nil || hasCoordinates else { return }

        let signature = [
            "\(userID)",
            "\(mapNodeID ?? 0)",
            currentNode.floor.assistanceFloorCode,
            String(format: "%.2f", Double(currentNode.x)),
            String(format: "%.2f", Double(currentNode.y)),
            currentNode.qr ?? ""
        ].joined(separator: "|")

        guard signature != lastUploadedLocationSignature else { return }
        lastUploadedLocationSignature = signature

        Task {
            do {
                try await MuseumNavAPIClient.shared.uploadUserLocation(
                    userID: userID,
                    mapNodeID: mapNodeID,
                    x: Double(currentNode.x),
                    y: Double(currentNode.y),
                    floorCode: currentNode.floor.assistanceFloorCode,
                    qrCode: currentNode.qr ?? lastScannedQR,
                    source: currentNode.qr == nil ? "coordinates" : "qr"
                )
            } catch {
                if lastUploadedLocationSignature == signature {
                    lastUploadedLocationSignature = nil
                }
            }
        }
    }

    func handleCameraError(_ error: CameraManager.CameraError) {
        switch error {
        case .unavailable:
            lastErrorMessage = lm.s(L.mapCameraUnavailable)
        case .inputConfigurationFailed:
            lastErrorMessage = lm.s(L.mapCameraInputError)
        }
    }

    func localizedNodeName(_ name: String) -> String {
        switch name {
        case L.mapNodeUsuarioDummy: return lm.s(L.mapNodeUsuarioDummy)
        case L.mapNodeEntradaPrincipal: return lm.s(L.mapNodeEntradaPrincipal)
        case L.mapNodeLobby: return lm.s(L.mapNodeLobby)
        case L.mapNodeBanos: return lm.s(L.mapNodeBanos)
        case L.mapNodeTiendaDeSouvenirs: return lm.s(L.mapNodeTiendaDeSouvenirs)
        case L.mapNodeTaquillaEInformacion: return lm.s(L.mapNodeTaquillaEInformacion)
        case L.mapNodeSnackH3: return lm.s(L.mapNodeSnackH3)
        case L.mapNodeElevadorInclinado: return lm.s(L.mapNodeElevadorInclinado)
        case L.mapNodePatioDeDemostraciones: return lm.s(L.mapNodePatioDeDemostraciones)
        case L.mapNodePaseoPorLasEstufas: return lm.s(L.mapNodePaseoPorLasEstufas)
        case L.mapNodeGaleriaDelAcero: return lm.s(L.mapNodeGaleriaDelAcero)
        case L.mapNodeGaleriaDeLaHistoria: return lm.s(L.mapNodeGaleriaDeLaHistoria)
        case L.mapNodeHornoAlto: return lm.s(L.mapNodeHornoAlto)
        case L.mapNodeExplanadaEstufas: return lm.s(L.mapNodeExplanadaEstufas)
        case L.mapNodeBanosAccesibles: return lm.s(L.mapNodeBanosAccesibles)
        case L.mapNodeAccesoAccesibleLobby: return lm.s(L.mapNodeAccesoAccesibleLobby)
        case L.mapNodeTerraza: return lm.s(L.mapNodeTerraza)
        case L.mapNodeShowHorno: return lm.s(L.mapNodeShowHorno)
        case L.mapNodeHornoAltoNivel2: return lm.s(L.mapNodeHornoAltoNivel2)
        case L.mapNodeH3PlanetaTierra: return lm.s(L.mapNodeH3PlanetaTierra)
        case L.mapNodePaseoPorLasEstufasNivel2: return lm.s(L.mapNodePaseoPorLasEstufasNivel2)
        case L.mapNodeRestauranteElLingote: return lm.s(L.mapNodeRestauranteElLingote)
        case L.mapNodeSalidaAccesoDerechoNivel2: return lm.s(L.mapNodeSalidaAccesoDerechoNivel2)
        case L.mapNodeElevadorInclinadoNivel2: return lm.s(L.mapNodeElevadorInclinadoNivel2)
        case L.mapNodeBanosNivel2: return lm.s(L.mapNodeBanosNivel2)
        case L.mapNodeAccesoAccesibleDerechoNivel2: return lm.s(L.mapNodeAccesoAccesibleDerechoNivel2)
        case L.mapNodeBocaDelHornoAlto: return lm.s(L.mapNodeBocaDelHornoAlto)
        case L.mapNodeMiradorCentral: return lm.s(L.mapNodeMiradorCentral)
        case L.mapNodeMiradorEste: return lm.s(L.mapNodeMiradorEste)
        case L.mapNodeMiradorSur: return lm.s(L.mapNodeMiradorSur)
        case L.mapNodeSalidaExtremoNivel3: return lm.s(L.mapNodeSalidaExtremoNivel3)
        case L.mapNodeElevadorInclinadoNivel3: return lm.s(L.mapNodeElevadorInclinadoNivel3)
        case L.mapNodeAccesoAccesibleMirador: return lm.s(L.mapNodeAccesoAccesibleMirador)
        case L.mapNodeEscalerasNivel1: return lm.s(L.mapNodeEscalerasNivel1)
        case L.mapNodeEscalerasNivel2: return lm.s(L.mapNodeEscalerasNivel2)
        case L.mapNodeEscalerasNivel3: return lm.s(L.mapNodeEscalerasNivel3)
        case L.mapNodeDesconocido: return lm.s(L.mapNodeDesconocido)
        case L.mapNodeEntrance: return lm.s(L.mapNodeEntrance)
        case L.mapNodeCentral: return lm.s(L.mapNodeCentral)
        case L.mapNodeBathrooms: return lm.s(L.mapNodeBathrooms)
        case L.mapNodeSnacks: return lm.s(L.mapNodeSnacks)
        case L.mapNodeSouvenirs: return lm.s(L.mapNodeSouvenirs)
        case L.mapNodeInfo: return lm.s(L.mapNodeInfo)
        case L.mapNodeRestArea: return lm.s(L.mapNodeRestArea)
        case L.mapNodeEmergencyExitNorth: return lm.s(L.mapNodeEmergencyExitNorth)
        case L.mapNodeEmergencyExitSouth: return lm.s(L.mapNodeEmergencyExitSouth)
        case L.mapNodeRampNorth: return lm.s(L.mapNodeRampNorth)
        case L.mapNodeRampSouth: return lm.s(L.mapNodeRampSouth)
        case L.mapNodeElevator: return lm.s(L.mapNodeElevator)
        default: return name
        }
    }

    func localizedRouteName(_ route: String) -> String {
        switch route {
        case L.mapRouteGeneral: return lm.s(L.mapRouteGeneral)
        case L.mapRouteSculptures: return lm.s(L.mapRouteSculptures)
        case L.mapRoutePaintings: return lm.s(L.mapRoutePaintings)
        default: return route
        }
    }

    private func localNodeDetails(for node: MuseumNavMapNode) -> MuseumNavNodeDetails {
        MuseumNavNodeDetails(
            id: node.id,
            name: localizedNodeName(node.name),
            nodeType: node.nodeType,
            image: localNodeImageName(for: node),
            description: localNodeDescription(for: node)
        )
    }

    private func localNodeImageName(for node: MuseumNavMapNode) -> String {
        switch node.name {
        case L.mapNodeLobby:
            return "museum_node_lobby"
        case L.mapNodeGaleriaDeLaHistoria:
            return "museum_node_historia"
        case L.mapNodeGaleriaDelAcero:
            return "museum_node_acero"
        case L.mapNodeBocaDelHornoAlto:
            return "museum_node_boca_horno_alto"
        case L.mapNodeMiradorCentral:
            return "museum_node_mirador_central"
        case L.mapNodeMiradorEste:
            return "museum_node_mirador_este"
        case L.mapNodeMiradorSur:
            return "museum_node_mirador_sur"
        case L.mapNodeElevadorInclinadoNivel3:
            return "museum_node_elevador_inclinado_n3"
        case L.mapNodeEscalerasNivel3:
            return "museum_node_escaleras_n3"
        case L.mapNodeHornoAlto, L.mapNodeHornoAltoNivel2, L.mapNodeShowHorno:
            return "museum_node_horno"
        default:
            return "horno3"
        }
    }

    private func localNodeDescription(for node: MuseumNavMapNode) -> String {
        switch node.name {
        case L.mapNodeGaleriaDeLaHistoria:
            return "Zona de historia del museo, con piezas y relatos vinculados al desarrollo industrial de Monterrey."
        case L.mapNodeGaleriaDelAcero:
            return "Galería dedicada al acero, sus procesos, maquinaria y objetos relacionados con la industria siderúrgica."
        case L.mapNodeHornoAlto, L.mapNodeHornoAltoNivel2, L.mapNodeBocaDelHornoAlto, L.mapNodeShowHorno:
            return "Área del Horno Alto, el eje histórico del museo y una de las estructuras industriales más representativas de Horno3."
        default:
            return "Ubicación seleccionada en el mapa interactivo de Horno3."
        }
    }

    private var clampedRouteIndex: Int {
        min(max(selectedRouteIndex, 0), max(routes.count - 1, 0))
    }

    private var clampedDestinationIndex: Int {
        min(max(selectedDestinationIndex, 0), max(destinations.count - 1, 0))
    }

    private func normalizeSelectedDestinationIndex() {
        selectedDestinationIndex = clampedDestinationIndex
    }

    private func destinationNodeForCurrentIndex() -> MuseumNavMapNode? {
        guard destinations.indices.contains(clampedDestinationIndex) else { return nil }
        let destination = destinations[clampedDestinationIndex]
        return nodes.first(where: { $0.name == destination && $0.floor == selectedFloor })
    }

    private var selectedRouteWaypointIDs: [Int] {
        switch clampedRouteIndex {
        case 1:
            // Ruta de exhibiciones historicas: cruza por acero, historia y el horno.
            return [10, 11, 12]
        case 2:
            // Ruta panoramica: conecta elevador, planeta tierra y mirador.
            return [7, 19, 27]
        default:
            // Ruta general: usa el camino mas directo entre origen y destino.
            return []
        }
    }

    private func selectedRouteWaypoints(
        from start: MuseumNavMapNode,
        to destination: MuseumNavMapNode,
        nodeByID: [Int: MuseumNavMapNode]
    ) -> [MuseumNavMapNode] {
        let waypoints = selectedRouteWaypointIDs.compactMap { nodeByID[$0] }

        guard start.floor == destination.floor else {
            return waypoints
        }

        return waypoints.filter { $0.floor == destination.floor }
    }

    private func buildAdjacency() -> [Int: [Int]] {
        var adjacency: [Int: [Int]] = [:]

        for edge in graphEdges {
            guard let fromNode = nodes.first(where: { $0.id == edge.from }),
                  let toNode = nodes.first(where: { $0.id == edge.to }),
                  isRouteAnchor(fromNode),
                  isRouteAnchor(toNode) else { continue }

            if isWheelchairModeEnabled, edge.kind == .stairs {
                continue
            }

            adjacency[edge.from, default: []].append(edge.to)
            adjacency[edge.to, default: []].append(edge.from)
        }

        return adjacency
    }

    private func nearestRoutableNode(
        to node: MuseumNavMapNode,
        among candidates: [MuseumNavMapNode],
        adjacency: [Int: [Int]]
    ) -> MuseumNavMapNode? {
        if adjacency[node.id] != nil,
           let exact = candidates.first(where: { $0.id == node.id }),
           isRouteAnchor(exact) {
            return exact
        }

        if let explicitAnchor = explicitRouteAnchor(for: node, among: candidates, adjacency: adjacency) {
            return explicitAnchor
        }

        guard node.id < 0 || node.qr != nil else { return nil }

        let floorCandidates = candidates.filter { $0.floor == node.floor }
        let scopedCandidates = floorCandidates.isEmpty ? candidates : floorCandidates

        return scopedCandidates
            .filter { adjacency[$0.id] != nil && isRouteAnchor($0) }
            .min(by: {
                distance(from: node, to: $0) < distance(from: node, to: $1)
            })
    }

    private func explicitRouteAnchor(
        for node: MuseumNavMapNode,
        among candidates: [MuseumNavMapNode],
        adjacency: [Int: [Int]]
    ) -> MuseumNavMapNode? {
        let candidateByID = Dictionary(uniqueKeysWithValues: candidates.map { ($0.id, $0) })
        let connectedAnchors = graphEdges.compactMap { edge -> MuseumNavMapNode? in
            let connectedID: Int

            if edge.from == node.id {
                connectedID = edge.to
            } else if edge.to == node.id {
                connectedID = edge.from
            } else {
                return nil
            }

            guard let connectedNode = candidateByID[connectedID],
                  connectedNode.floor == node.floor,
                  isRouteAnchor(connectedNode),
                  adjacency[connectedNode.id] != nil else { return nil }

            return connectedNode
        }

        return connectedAnchors.min {
            distance(from: node, to: $0) < distance(from: node, to: $1)
        }
    }

    private func isRouteAnchor(_ node: MuseumNavMapNode) -> Bool {
        switch node.nodeType {
        case "filler", "entry", "hall", "stairs", "accessibility":
            return true
        default:
            return false
        }
    }

    private func shortestPath(
        from start: Int,
        to goal: Int,
        nodeByID: [Int: MuseumNavMapNode],
        adjacency: [Int: [Int]]
    ) -> [Int]? {
        var unsettled: Set<Int> = [start]
        var settled: Set<Int> = []
        var cameFrom: [Int: Int] = [:]
        var cost: [Int: CGFloat] = [start: 0]

        while let current = unsettled.min(by: { (cost[$0] ?? .greatestFiniteMagnitude) < (cost[$1] ?? .greatestFiniteMagnitude) }) {
            if current == goal {
                return reconstructPath(cameFrom: cameFrom, current: current)
            }

            unsettled.remove(current)
            settled.insert(current)

            for neighbor in adjacency[current] ?? [] {
                guard !settled.contains(neighbor) else { continue }

                let tentativeCost = (cost[current] ?? .greatestFiniteMagnitude)
                    + traversalCost(from: current, to: neighbor, nodeByID: nodeByID)

                if tentativeCost < (cost[neighbor] ?? .greatestFiniteMagnitude) {
                    cameFrom[neighbor] = current
                    cost[neighbor] = tentativeCost
                    unsettled.insert(neighbor)
                }
            }
        }

        return nil
    }

    private func reconstructPath(cameFrom: [Int: Int], current: Int) -> [Int] {
        var path = [current]
        var cursor = current

        while let previous = cameFrom[cursor] {
            path.insert(previous, at: 0)
            cursor = previous
        }

        return path
    }

    private func traversalCost(from start: Int, to goal: Int, nodeByID: [Int: MuseumNavMapNode]) -> CGFloat {
        guard let startNode = nodeByID[start], let goalNode = nodeByID[goal] else { return .greatestFiniteMagnitude }
        let baseCost = distance(from: startNode, to: goalNode)

        if isWheelchairModeEnabled, edgeKind(between: start, and: goal) == .elevator {
            return baseCost * 0.35
        }

        return baseCost
    }

    private func edgeKind(between start: Int, and goal: Int) -> MuseumNavGraphEdgeKind? {
        graphEdges.first {
            ($0.from == start && $0.to == goal) || ($0.from == goal && $0.to == start)
        }?.kind
    }

    private func distance(from lhs: MuseumNavMapNode, to rhs: MuseumNavMapNode) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    private func deduplicated(path: [MuseumNavMapNode]) -> [MuseumNavMapNode] {
        var seen: Set<Int> = []
        return path.filter { seen.insert($0.id).inserted }
    }

}

private struct MuseumNavGraphEdge {
    let from: Int
    let to: Int
    let kind: MuseumNavGraphEdgeKind

    init(from: Int, to: Int, kind: MuseumNavGraphEdgeKind = .walkway) {
        self.from = from
        self.to = to
        self.kind = kind
    }
}

private enum MuseumNavGraphEdgeKind {
    case walkway
    case stairs
    case elevator
}

struct MuseumNavNodeDetails {
    let id: Int
    let name: String
    let nodeType: String?
    let image: String
    let description: String
}

private struct MuseumNavUserLocationPayload: Encodable {
    let userId: Int
    let mapNodeID: Int?
    let x: Double
    let y: Double
    let floorCode: String
    let qrCode: String?
    let source: String
}

private struct MuseumNavAPIClient {
    static let shared = MuseumNavAPIClient()

    private let baseURL = URL(string: Config.serverRootURL)!

    func uploadUserLocation(
        userID: Int,
        mapNodeID: Int?,
        x: Double,
        y: Double,
        floorCode: String,
        qrCode: String?,
        source: String
    ) async throws {
        let url = baseURL.appending(path: "map/user-location")
        let payload = MuseumNavUserLocationPayload(
            userId: userID,
            mapNodeID: mapNodeID,
            x: x,
            y: y,
            floorCode: floorCode,
            qrCode: qrCode,
            source: source
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }
}
