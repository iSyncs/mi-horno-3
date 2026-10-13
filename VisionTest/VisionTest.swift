import XCTest
@testable import Mi_Horno_3

@MainActor
final class MuseumNavViewModelTests: XCTestCase {
    func testUpdatePositionWithValidQRUpdatesCurrentNode() {
        let viewModel = MuseumNavViewModel()

        viewModel.updatePosition(qr: "QR_CENTRAL")

        XCTAssertNotNil(viewModel.currentNode)
        XCTAssertEqual(viewModel.currentNode?.id, 2)
        XCTAssertEqual(viewModel.currentNode?.name, "Nodo Central")
        XCTAssertEqual(viewModel.currentNode?.qr, "QR_CENTRAL")
    }

    func testUpdatePositionWithInvalidQRDoesNotUpdateNode() {
        let viewModel = MuseumNavViewModel()

        viewModel.updatePosition(qr: "QR_INEXISTENTE")

        XCTAssertEqual(viewModel.currentNode?.qr, "QR_INEXISTENTE")
    }

    func testUpdatePositionChangesToBathroomNode() {
        let viewModel = MuseumNavViewModel()

        viewModel.updatePosition(qr: "QR_BANO1")

        XCTAssertNotNil(viewModel.currentNode)
        XCTAssertEqual(viewModel.currentNode?.id, 3)
        XCTAssertEqual(viewModel.currentNode?.name, L.mapNodeBathrooms)
    }

    func testDisplayedNodesHideAccessibilityWhenWheelchairModeIsDisabled() {
        let viewModel = MuseumNavViewModel()

        XCTAssertFalse(viewModel.displayedNodes.contains(where: { $0.nodeType == "accessibility" }))
    }

    func testDisplayedNodesIncludeAccessibilityWhenWheelchairModeIsEnabled() {
        let viewModel = MuseumNavViewModel()
        viewModel.isWheelchairModeEnabled = true

        XCTAssertTrue(viewModel.displayedNodes.contains(where: { $0.nodeType == "accessibility" }))
    }

    func testPrioritizedNodeTypesOnlyAppearInWheelchairMode() {
        let viewModel = MuseumNavViewModel()
        XCTAssertTrue(viewModel.prioritizedNodeTypes.isEmpty)

        viewModel.isWheelchairModeEnabled = true
        XCTAssertEqual(viewModel.prioritizedNodeTypes, ["accessibility", "entry", "hall", "exit"])
    }

    func testHandleCameraErrorUpdatesUserFacingMessage() {
        let viewModel = MuseumNavViewModel()

        viewModel.handleCameraError(.unavailable)
        XCTAssertEqual(viewModel.lastErrorMessage, LocalizationManager.shared.s(L.mapCameraUnavailable))
    }
}
