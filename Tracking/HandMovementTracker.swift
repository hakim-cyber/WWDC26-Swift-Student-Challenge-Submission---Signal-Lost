import AVFoundation
import Vision
import CoreGraphics
import SwiftUI

extension HandMovementTracker: @unchecked Sendable {}




final class HandMovementTracker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

  
    var onCursor: (@MainActor (CGPoint?) -> Void)?
    var onIndexTip: (@MainActor (CGPoint?) -> Void)?
    var onThumbTip: (@MainActor (CGPoint?) -> Void)?
    var onPinchChanged: (@MainActor (Bool) -> Void)?
    var onClick: (@MainActor () -> Void)?
    var onRotation: (@MainActor (CGFloat) -> Void)?

   
    var onFacePresent: (@MainActor (Bool) -> Void)?
    var onEyeClosure: (@MainActor (CGFloat) -> Void)?
    var onEyeSymbol: (@MainActor (EyeGestureHandler.EyeSymbol) -> Void)?

   
    var captureSession: AVCaptureSession { session }

 
    var cursorConfidence: Float = 0.20
    var smoothingAlpha: CGFloat = 0.30

  
    var pinchConfidence: Float = 0.75
    var pinchDownThreshold: CGFloat = 0.045
    var pinchUpThreshold: CGFloat = 0.060
    var clickOnRelease: Bool = false

  
    var rotationConfidence: Float = 0.45
    var rotationSmoothingAlpha: CGFloat = 0.22

  
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoQueue = DispatchQueue(label: "camera.video.queue")

    private var configured = false

    private let handPoseRequest: VNDetectHumanHandPoseRequest = {
        let r = VNDetectHumanHandPoseRequest()
        r.maximumHandCount = 1
        return r
    }()

    private var isPinched = false
    private var lastSentPinch: Bool?

    private var smoothedCursor: CGPoint?
    private var smoothedRotation: CGFloat?

    private var lastGoodCursor: CGPoint?
    private var lastGoodTime: CFTimeInterval = 0
    private let holdDuration: CFTimeInterval = 0.10

  
    private let eye = EyeGestureHandler()
  
       var eyeEnabled: Bool = false

      
       func setEyeEnabled(_ enabled: Bool) {
           eyeEnabled = enabled
           if enabled { eye.reset() }
       }


   
    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.configured {
                self.configureCamera()
                self.configureEyeCallbacks()
                self.configured = true
            }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

  
    private func configureCamera() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device)
        else {
            session.commitConfiguration()
            return
        }

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)

        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }

        if let conn = videoOutput.connection(with: .video) {
            conn.isVideoMirrored = true
        }

        session.commitConfiguration()
        updateConnectionOrientation()
    }

    func updateConnectionOrientation() {
        #if targetEnvironment(macCatalyst)
        sessionQueue.async { [weak self] in
            guard let self, let conn = self.videoOutput.connection(with: .video) else { return }
            if conn.isVideoRotationAngleSupported(0) {
                conn.videoRotationAngle = 0
            }
        }
        #else
        sessionQueue.async { [weak self] in
            guard let self,
                  let conn = self.videoOutput.connection(with: .video),
                  let device = (self.session.inputs.first as? AVCaptureDeviceInput)?.device else { return }
            
            if #available(iOS 17.0, *) {
              
                let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: nil)
                let angle = coordinator.videoRotationAngleForHorizonLevelCapture
                
                if conn.isVideoRotationAngleSupported(angle) {
                    conn.videoRotationAngle = angle
                }
            }
        }
        #endif
    }

    
    private func configureEyeCallbacks() {
        eye.onFacePresent = { [weak self] present in
            let cb = self?.onFacePresent
            Task { @MainActor in cb?(present) }
        }

        eye.onEyeClosure = { [weak self] closure in
            let cb = self?.onEyeClosure
            Task { @MainActor in cb?(closure) }
        }

        eye.onSymbol = { [weak self] symbol in
            let cb = self?.onEyeSymbol
            Task { @MainActor in cb?(symbol) }
        }
    }

  
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        if eyeEnabled {
       
            eye.process(sampleBuffer: sampleBuffer)
        }
       
        let handler = VNImageRequestHandler(
            cmSampleBuffer: sampleBuffer,
            orientation: .up,
            options: [:]
        )

        do { try handler.perform([handPoseRequest]) }
        catch { return }

        let cursorHandler = onCursor
        let indexHandler  = onIndexTip
        let thumbHandler  = onThumbTip
        let pinchHandler  = onPinchChanged
        let clickHandler  = onClick
        let rotationHandler = onRotation

        guard let observation = handPoseRequest.results?.first else {
            publishNoHand(cursorHandler, indexHandler, thumbHandler, pinchHandler)
            return
        }

        do {
            let points = try observation.recognizedPoints(.all)

            let indexTip = point(points, .indexTip, cursorConfidence)
            let thumbTip = point(points, .thumbTip, cursorConfidence)

            let wrist    = point(points, .wrist, rotationConfidence)
            let indexMCP = point(points, .indexMCP, rotationConfidence)

            let pinchConfOK =
                confidence(points, .indexTip) >= pinchConfidence &&
                confidence(points, .thumbTip) >= pinchConfidence

            let (pinched, didClick) =
                computePinch(indexTip, thumbTip, pinchConfOK)

            isPinched = pinched

            let cursor = heldAndSmoothedCursor(
                computeCursor(indexTip, thumbTip)
            )

            let rotation =
                (wrist != nil && indexMCP != nil)
                ? smoothAngle(angle(from: wrist!, to: indexMCP!))
                : nil

            let pinchChanged = lastSentPinch != pinched
            if pinchChanged { lastSentPinch = pinched }

            Task { @MainActor in
                cursorHandler?(cursor)
                indexHandler?(indexTip)
                thumbHandler?(thumbTip)
                if pinchChanged { pinchHandler?(pinched) }
                if didClick { clickHandler?() }
                if let rotation { rotationHandler?(rotation) }
            }

        } catch {
            publishNoHand(cursorHandler, indexHandler, thumbHandler, pinchHandler)
        }
    }


    private func publishNoHand(
        _ cursor: (@MainActor (CGPoint?) -> Void)?,
        _ index: (@MainActor (CGPoint?) -> Void)?,
        _ thumb: (@MainActor (CGPoint?) -> Void)?,
        _ pinch: (@MainActor (Bool) -> Void)?
    ) {
        let now = CACurrentMediaTime()
        let held = (now - lastGoodTime) <= holdDuration ? lastGoodCursor : nil
        if held == nil { smoothedCursor = nil }
        smoothedRotation = nil

        Task { @MainActor in
            cursor?(held)
            index?(nil)
            thumb?(nil)
            pinch?(false)
        }
    }

    private func point(
        _ points: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint],
        _ joint: VNHumanHandPoseObservation.JointName,
        _ min: Float
    ) -> CGPoint? {
        guard let p = points[joint], p.confidence >= min else { return nil }
        return CGPoint(x: p.location.x, y: 1 - p.location.y)
    }

    private func confidence(
        _ points: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint],
        _ joint: VNHumanHandPoseObservation.JointName
    ) -> Float {
        points[joint]?.confidence ?? 0
    }

    private func computeCursor(_ i: CGPoint?, _ t: CGPoint?) -> CGPoint? {
        switch (i, t) {
        case let (a?, b?): return midpoint(a, b)
        case let (a?, nil): return a
        case let (nil, b?): return b
        default: return nil
        }
    }

    private func heldAndSmoothedCursor(_ raw: CGPoint?) -> CGPoint? {
        let now = CACurrentMediaTime()
        let c = raw ?? ((now - lastGoodTime) <= holdDuration ? lastGoodCursor : nil)
        if let c {
            lastGoodCursor = c
            lastGoodTime = now
            return smoothCursor(c)
        }
        smoothedCursor = nil
        return nil
    }

    private func computePinch(
        _ i: CGPoint?,
        _ t: CGPoint?,
        _ ok: Bool
    ) -> (Bool, Bool) {
        let prev = isPinched
        var next = prev
        var click = false

        guard let i, let t, ok else { return (prev, false) }

        let d = hypot(i.x - t.x, i.y - t.y)
        if !prev && d < pinchDownThreshold {
            next = true
            if !clickOnRelease { click = true }
        } else if prev && d > pinchUpThreshold {
            next = false
            if clickOnRelease { click = true }
        }
        return (next, click)
    }

    private func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) * 0.5, y: (a.y + b.y) * 0.5)
    }

    private func smoothCursor(_ n: CGPoint) -> CGPoint {
        guard let p = smoothedCursor else {
            smoothedCursor = n
            return n
        }
        let a = smoothingAlpha
        let out = CGPoint(
            x: p.x + a * (n.x - p.x),
            y: p.y + a * (n.y - p.y)
        )
        smoothedCursor = out
        return out
    }

    private func angle(from a: CGPoint, to b: CGPoint) -> CGFloat {
        atan2(b.y - a.y, b.x - a.x)
    }

    private func normalizeAngle(_ x: CGFloat) -> CGFloat {
        var a = x
        while a > .pi { a -= 2 * .pi }
        while a < -.pi { a += 2 * .pi }
        return a
    }

    private func smoothAngle(_ n: CGFloat) -> CGFloat {
        guard let p = smoothedRotation else {
            smoothedRotation = n
            return n
        }
        let d = normalizeAngle(n - p)
        let out = p + rotationSmoothingAlpha * d
        smoothedRotation = out
        return out
    }
}
