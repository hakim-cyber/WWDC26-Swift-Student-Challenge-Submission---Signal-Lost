import SwiftUI
import AVFoundation
import Vision

struct ShowHandView: View {
    @State private var vm = RecoveryToCameraVM()
    var done: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 18)

                if vm.phase == .camera {
                    EmergencyInteractionDialogOverlay(
                                visible: vm.cameraOpacity > 0.15 && !vm.gameReady
                            )
                            .frame(maxWidth: 520)
                            .padding(.top, 6)

                }
               

                ZStack {
                  
                    if vm.phase == .systemText {
                        VStack(alignment: .leading, spacing: 12) {
                            if let l1 = vm.line1 { SystemLine(l1) }
                            if let l2 = vm.line2 { SystemLine(l2) }
                            if let l3 = vm.line3 { SystemLine(l3) }
                            if let l4 = vm.line4 { SystemLine(l4) }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(24)
                        .opacity(vm.textOpacity)
                        .transition(.opacity)
                    }

                   
                    if vm.phase == .camera {
                       
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )

                        ZStack {
                            CameraPreviewView(session: vm.camera.session)
                                .opacity(vm.cameraOpacity)
                                .blur(radius: vm.cameraBlur)
                                .frame(width: 600, height: 400, alignment: .center)
                                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                                .transition(.opacity)

                          
                            if vm.cameraOpacity > 0.05 && !vm.handDetected && !vm.gameReady {
                                HintChip(text: "Place your hand in frame")
                                    .transition(.opacity)
                            }

                         
                            if vm.handDetected && !vm.gameReady {
                                HintChip(text: "Hand detected • Pinch to start\n(thumb + index fingers touch)")
                                    .transition(.opacity)
                            }

                           
                            if vm.gameReady {
                                HintChip(text: "Starting…")
                                    .transition(.opacity)
                            }

                          
                            if vm.handDetected && !vm.gameReady {
                                HandHalo()
                                    .transition(.opacity)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
                .frame(width: 600, height: 400, alignment: .center)
                if vm.phase == .camera {
                    Text(vm.footerText)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer(minLength: 18)
                Spacer()
            }
        }
        .task { await vm.startSequence() }
        .onDisappear { vm.stop() }
        .onChange(of: vm.gameReady){old,new in
            if new{
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5){
                    self.done()
                }
            }
        }
    }
}


private struct EmergencyInteractionDialogOverlay: View {
    let visible: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text("Emergency Control Setup")
                .font(.system(size: 16.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))

            Text("""
The system needs your help.
You will use optical controls to restore power and send a signal for help.
""")
            .font(.system(size: 13.5, weight: .regular))
            .foregroundStyle(.white.opacity(0.70))
            .multilineTextAlignment(.center)
            .lineSpacing(2)

            Text("Start setup")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.black.opacity(0.95))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule(style: .continuous).fill(Color.white.opacity(0.92)))
                .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 0)
                .opacity(0.95)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(width: 520)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.45), radius: 28, x: 0, y: 18)
        .opacity(visible ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.35), value: visible)
        .allowsHitTesting(false) 
    }
}



private struct SystemLine: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 25, weight: .regular, design: .monospaced))
            .foregroundStyle(Color.white.opacity(0.92))
    }
}

private struct HintChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 15.5, weight: .semibold, design: .monospaced))
            .foregroundStyle(.black.opacity(0.95))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule(style: .continuous).fill(Color.white.opacity(0.92)))
            .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 0)
    }
}

private struct HandHalo: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 2)
                .blur(radius: 10)
                .scaleEffect(1.15)

            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 2)
                .blur(radius: 18)
                .scaleEffect(1.45)

            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 2)
                .blur(radius: 30)
                .scaleEffect(1.8565)
        }
        .frame(width: 420, height: 420)
    }
}


@Observable
@MainActor
final class RecoveryToCameraVM {

    enum Phase {
        case systemText
        case camera
    }

     var phase: Phase = .systemText

   
     var line1: String?
     var line2: String?
     var line3: String?
     var line4: String?
     var textOpacity: Double = 1.0

  
     var cameraOpacity: Double = 0.0
     var cameraBlur: CGFloat = 26

  
     var handDetected: Bool = false
     var gameReady: Bool = false

    @ObservationIgnored  let camera = HandPinchCamera()
    @ObservationIgnored private var started = false

   
    @ObservationIgnored  private let revealBlur: CGFloat = 18
    @ObservationIgnored  private let fullSharpBlur: CGFloat = 0

    var footerText: String {
        if phase == .systemText { return "> system: diagnostics" }
        if gameReady { return "> state: launching game" }
        if handDetected { return "> input: hand online (pinch to start)" }
        return "> input: waiting for hand"
    }

    func startSequence() async {
        guard !started else { return }
        started = true

       
        camera.onHandDetected = { [weak self] detected in
           
                guard let self else { return }

                if detected && !self.handDetected && !self.gameReady {
                    self.handDetected = true
                  
                    withAnimation(.easeInOut(duration: 1.0)) {
                        self.cameraBlur = self.fullSharpBlur
                    }
                } else if !detected && self.handDetected && !self.gameReady {
                 
                    self.handDetected = false
                    withAnimation(.easeInOut(duration: 0.8)) {
                        self.cameraBlur = self.revealBlur
                    }
                }
            
        }

        
        camera.onPinchDetected = { [weak self] in
          
                guard let self else { return }
                guard self.phase == .camera, self.handDetected, !self.gameReady else { return }
               
                
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.gameReady = true
                }
                AudioManager.shared.playSFX(.confirm)

               
            
        }

        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.camera.updateConnectionOrientation()
            }
        }
      
        clearSystemText()
        textOpacity = 1.0
        phase = .systemText

        try? await Task.sleep(nanoseconds: 2_000_000_000)

       
        withAnimation(.easeInOut(duration: 0.35)) { line1 = "Something went wrong." }
         AudioManager.shared.typeForLine(line1)
        try? await Task.sleep(nanoseconds: 1000_000_000)

        withAnimation(.easeInOut(duration: 0.35)) { line2 = "The computer cannot detect touch or keyboard input." }
         AudioManager.shared.typeForLine(line2)
        try? await Task.sleep(nanoseconds: 1400_000_000)

        withAnimation(.easeInOut(duration: 0.35)) { line3 = "For safety reasons, direct interaction is disabled." }
         AudioManager.shared.typeForLine(line3)
        try? await Task.sleep(nanoseconds: 1400_000_000)

       
        withAnimation(.easeInOut(duration: 0.8)) { textOpacity = 0.0 }
        try? await Task.sleep(nanoseconds: 2_000_000_000)

       
        clearSystemText()
        textOpacity = 1.0
        withAnimation(.easeInOut(duration: 0.45)) {
            line4 = "Emergency optical controls enabled."
        }
         AudioManager.shared.typeForLine(line4)
       
        try? await Task.sleep(nanoseconds: 900_000_000)

       
        withAnimation(.easeInOut(duration: 0.7)) { textOpacity = 0.0 }
        try? await Task.sleep(nanoseconds: 700_000_000)

       
        phase = .camera
        handDetected = false
        gameReady = false

        cameraBlur = 26
        cameraOpacity = 0.0

     
        try? await Task.sleep(nanoseconds: 350_000_000)

        camera.start()

        withAnimation(.easeInOut(duration: 1.2)) {
            cameraOpacity = 1.0
            cameraBlur = revealBlur
        }

    }

    func stop() {
        camera.stop()
    }

    private func clearSystemText() {
        line1 = nil
        line2 = nil
        line3 = nil
        line4 = nil
    }
}


extension HandPinchCamera: @unchecked Sendable {}
final class HandPinchCamera: NSObject {
    let session = AVCaptureSession()
     private let output = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "recovery.camera.session")
    private let videoQueue = DispatchQueue(label: "recovery.camera.video")

     var onHandDetected: (@MainActor (Bool) -> Void)?
      var onPinchDetected: (@MainActor () -> Void)?

    private let handRequest: VNDetectHumanHandPoseRequest = {
        let r = VNDetectHumanHandPoseRequest()
        r.maximumHandCount = 1
        return r
    }()

    private var configured = false

   
    private var lastHandDetected = false
    private var lastEmitTime: CFTimeInterval = 0
    private var lastPinchTime: CFTimeInterval = 0

   
    private let pinchDistanceThreshold: CGFloat = 0.06
    private let pinchCooldown: CFTimeInterval = 0.8

    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.configureIfNeeded()
            guard self.configured else { return }
            if !self.session.isRunning { self.session.startRunning() }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    private func configureIfNeeded() {
        guard !configured else { return }
        configured = true

        session.beginConfiguration()
        session.sessionPreset = .high

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device)
        else {
            session.commitConfiguration()
            return
        }

     

        
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoQueue)

        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }

        if let conn = output.connection(with: .video) {
            conn.isVideoMirrored = true
        }

        session.commitConfiguration()
        updateConnectionOrientation()
    }
  
    func updateConnectionOrientation() {
        #if targetEnvironment(macCatalyst)
        sessionQueue.async { [weak self] in
            guard let self, let conn = self.output.connection(with: .video) else { return }
            if conn.isVideoRotationAngleSupported(0) {
                conn.videoRotationAngle = 0
            }
        }
        #else
        sessionQueue.async { [weak self] in
            guard let self,
                  let conn = self.output.connection(with: .video),
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
}

extension HandPinchCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

        do {
            try handler.perform([handRequest])

            guard let obs = handRequest.results?.first else {
                Task { @MainActor in
                    emitHandDetected(false)
                }
                return
            }

            let thumbTip = try? obs.recognizedPoint(.thumbTip)
            let indexTip = try? obs.recognizedPoint(.indexTip)

            let thumbOK = (thumbTip?.confidence ?? 0) > 0.25
            let indexOK = (indexTip?.confidence ?? 0) > 0.25

            let hasHand = thumbOK || indexOK
            Task { @MainActor in
                emitHandDetected(hasHand)
            }

            
            if thumbOK, indexOK, let t = thumbTip, let i = indexTip {
                let dx = t.location.x - i.location.x
                let dy = t.location.y - i.location.y
                let dist = sqrt(dx*dx + dy*dy)

                if dist < pinchDistanceThreshold {
                    Task { @MainActor in
                        emitPinch()
                    }
                }
            }

        } catch {
           
        }
    }

    @MainActor private func emitHandDetected(_ detected: Bool) {
        let now = CACurrentMediaTime()
        if detected != lastHandDetected && (now - lastEmitTime) > 0.15 {
            lastHandDetected = detected
            lastEmitTime = now
            onHandDetected?(detected)
        }
    }

    @MainActor private func emitPinch() {
        let now = CACurrentMediaTime()
        guard (now - lastPinchTime) > pinchCooldown else { return }
        lastPinchTime = now
        onPinchDetected?()
    }
}
