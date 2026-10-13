import Foundation
import CoreGraphics

enum MuseumNavFloor: Int, CaseIterable, Identifiable {
    case level1 = 1
    case level2 = 2
    case level3 = 3

    var id: Int { rawValue }

    var title: String {
        "Nivel \(rawValue)"
    }

    var shortTitle: String {
        "N\(rawValue)"
    }

    var assetName: String {
        "museum_floor_\(rawValue)"
    }

    var assistanceFloorCode: String {
        switch self {
        case .level1: return "L1"
        case .level2: return "L2"
        case .level3: return "L3"
        }
    }

    var canvasSize: CGSize {
        CGSize(width: 1920.0, height: 1080.0)
    }

    var focusRect: CGRect {
        switch self {
        case .level1:
            return CGRect(x: 20.0, y: 24.0, width: 1760.0, height: 1016.0)
        case .level2:
            return CGRect(x: 24.0, y: 28.0, width: 1790.0, height: 980.0)
        case .level3:
            return CGRect(x: 220.0, y: 20.0, width: 1420.0, height: 1012.0)
        }
    }

    var imageAspectRatio: CGFloat {
        focusRect.width / focusRect.height
    }

    init?(floorCode: String?) {
        guard let floorCode else { return nil }
        switch floorCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased() {
        case "PB", "P0", "N0", "L1", "LEVEL1", "NIVEL1", "PLANTA BAJA":
            self = .level1
        case "P1", "N1", "L2", "LEVEL2", "NIVEL2":
            self = .level2
        case "P2", "N2", "L3", "LEVEL3", "NIVEL3":
            self = .level3
        default:
            return nil
        }
    }
}

struct MuseumNavMapNode: Identifiable, Equatable {
    let id: Int
    let name: String
    let x: CGFloat
    let y: CGFloat
    let floor: MuseumNavFloor

    let qr: String?
    let nodeType: String?

    init(id: Int,
         name: String,
         x: CGFloat,
         y: CGFloat,
         floor: MuseumNavFloor = .level1,
         qr: String? = nil,
         nodeType: String? = nil) {
        self.id = id
        self.name = name
        self.x = x
        self.y = y
        self.floor = floor
        self.qr = qr
        self.nodeType = nodeType
    }
}
