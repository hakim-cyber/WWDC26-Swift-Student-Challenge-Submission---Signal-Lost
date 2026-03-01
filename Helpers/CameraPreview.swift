
import SwiftUI
import AVFoundation

final class CameraPreview: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
        previewLayer.videoGravity = .resizeAspectFill
       
        
        updateConnectionOrientation()
      
    }
    @MainActor
    private func currentInterfaceOrientationOnMain() -> UIInterfaceOrientation {
        
        guard let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .portrait
        }

        if #available(iOS 26.0, macCatalyst 26.0, *) {
            return ws.effectiveGeometry.interfaceOrientation
        } else {
            return ws.interfaceOrientation
        }
    }

    private func rotationAngle(for orientation: UIInterfaceOrientation) -> CGFloat {
        switch orientation {
        case .portrait: return 270
        case .landscapeRight: return 0
        case .portraitUpsideDown: return 90
        case .landscapeLeft: return 180
        default: return 270
        }
    }

    private func applyOrientation(ui: UIInterfaceOrientation, to conn: AVCaptureConnection) {
        let angle = rotationAngle(for: ui)

        if #available(iOS 17.0, macCatalyst 17.0, *) {
            if conn.isVideoRotationAngleSupported(angle) {
                conn.videoRotationAngle = angle
            }
        }
        
    }
    func updateConnectionOrientation() {
        #if targetEnvironment(macCatalyst)
        guard let connection = self.previewLayer.connection else { return }
        if connection.isVideoRotationAngleSupported(0) {
            connection.videoRotationAngle = 0
        }
        #else
      
        guard let connection = self.previewLayer.connection,
              let device = (self.previewLayer.session?.inputs.first as? AVCaptureDeviceInput)?.device else { return }

      
        if #available(iOS 17.0, *) {
            let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: self.previewLayer)
            let angle = coordinator.videoRotationAngleForHorizonLevelPreview
            
            if connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
        } else {
         
        }
        #endif
    }
}


struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreview {
        let view = CameraPreview()
        view.previewLayer.session = session
        view.updateConnectionOrientation()
        return view
    }

    func updateUIView(_ uiView: CameraPreview, context: Context) {
       
    }
}
