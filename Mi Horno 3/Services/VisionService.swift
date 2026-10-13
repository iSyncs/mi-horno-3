import Vision
import CoreML
import UIKit
import Combine

final class VisionService: ObservableObject {
    @Published var classificationLabel: String = ""
    @Published var confidence: Float = 0.0
    @Published var topClassifications: [ClassificationResult] = []

    struct ClassificationResult: Identifiable, Hashable {
        var id: String { label }
        let label: String
        let confidence: Float
    }
    
    private lazy var classificationRequest: VNCoreMLRequest? = {
        do {
            let config = MLModelConfiguration()
            #if targetEnvironment(simulator)
            config.computeUnits = .cpuOnly
            #else
            config.computeUnits = .all
            #endif
            
            let model = try VNCoreMLModel(for: ClassifierFinal(configuration: config).model)
            
            let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            }
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            print("Error al cargar el modelo: \(error)")
            return nil
        }
    }()
    
    func classify(image: CVPixelBuffer) {
        guard let request = classificationRequest else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        try? handler.perform([request])
    }
    
    func classify(image: UIImage, completion: (() -> Void)? = nil) {
        guard let request = classificationRequest else {
            DispatchQueue.main.async { completion?() }
            return
        }
        
        let normalizedImage = image.normalizedForVision()
        
        guard let cgImage = normalizedImage.cgImage else {
            DispatchQueue.main.async { completion?() }
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    private func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.classificationLabel = "Error: \(error.localizedDescription)"
                self.confidence = 0
                self.topClassifications = []
                return
            }
            guard let results = request.results as? [VNClassificationObservation] else {
                self.classificationLabel = "Error: No es VNClassification"
                self.confidence = 0
                self.topClassifications = []
                return
            }
            guard let firstResult = results.first else {
                self.classificationLabel = "Error: Vacio"
                self.confidence = 0
                self.topClassifications = []
                return
            }
            
            self.classificationLabel = firstResult.identifier
            self.confidence = firstResult.confidence
            self.topClassifications = results.prefix(3).map {
                ClassificationResult(label: $0.identifier, confidence: $0.confidence)
            }
        }
    }
}

private extension UIImage {
    func normalizedForVision() -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Safe Orientation Extension
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}
