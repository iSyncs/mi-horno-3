import AVFoundation
import Vision

final class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()

    var onQRCodeDetected: ((String) -> Void)?
    var onError: ((CameraError) -> Void)?

    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "camera.queue")
    private var hasConfiguredSession = false

    enum CameraError: Error {
        case unavailable
        case inputConfigurationFailed
    }

    func start() {
        if !hasConfiguredSession {
            session.beginConfiguration()

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .back) else {
                session.commitConfiguration()
                DispatchQueue.main.async { [weak self] in
                    self?.onError?(.unavailable)
                }
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: device)

                if session.canAddInput(input) {
                    session.addInput(input)
                }
            } catch {
                session.commitConfiguration()
                DispatchQueue.main.async { [weak self] in
                    self?.onError?(.inputConfigurationFailed)
                }
                return
            }

            videoOutput.setSampleBufferDelegate(self, queue: queue)
            videoOutput.alwaysDiscardsLateVideoFrames = true

            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }

            session.commitConfiguration()
            hasConfiguredSession = true
        }

        guard !session.isRunning else { return }
        queue.async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                print("Camera session started")
            }
        }
    }

    func stop() {
        guard session.isRunning else { return }
        queue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        processFrame(pixelBuffer)
    }

    private func processFrame(_ pixelBuffer: CVPixelBuffer) {
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            if let error = error {
                print("Vision error:", error)
                return
            }

            guard let results = request.results as? [VNBarcodeObservation] else {
                return
            }

            for barcode in results {
                guard let qr = barcode.payloadStringValue else { continue }
                DispatchQueue.main.async {
                    self?.onQRCodeDetected?(qr)
                }
            }
        }

        request.symbologies = [.qr]

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
}
