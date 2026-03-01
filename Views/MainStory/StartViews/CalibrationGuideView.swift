import Foundation
import SwiftUI
import AVFoundation



struct CalibrationGuideView: View {
    @State private var vm = CalibrationGuideVM()
    var done: () -> Void

    var body: some View {
        ZStack {
           
            CameraPreviewView(session: vm.session)
                .ignoresSafeArea()
                .opacity(0.85)
                .blur(radius: vm.cameraBlur)
                .overlay(Color.black.opacity(0.55))
                .allowsHitTesting(false)

         
            RadialGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.85)]),
                center: .center,
                startRadius: 120,
                endRadius: 900
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

           
            VStack(spacing: 18) {
                Text("CALIBRATION")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.60))
                    .padding(.top, 10)

                Text("Make sure the camera can see you.")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                let cols = [GridItem(.flexible()), GridItem(.flexible())]

                LazyVGrid(columns: cols, spacing: 14) {
                    CalibrationCard(
                        imageName: "hand_full",
                        title: "HAND IN FRAME",
                        subtitle: "Keep one hand fully visible.",
                        state: vm.handOK ? .ok : .idle
                    )

                    CalibrationCard(
                        imageName: "pinch",
                        title: "PINCH",
                        subtitle: "Thumb + index fingers pinch to interact.",
                        state: vm.pinchOK ? .ok : .idle
                    )

                    CalibrationCard(
                        imageName: "pinch_rotate",
                        title: "ROTATE",
                        subtitle: "Pinch, then rotate your wrist.",
                        state: vm.rotateOK ? .ok : .idle
                    )

                    CalibrationCard(
                        imageName: "eye_head",
                        title: "EYE MORSE",
                        subtitle: "Keep your head fully in view.",
                        state: vm.faceOK ? .ok : .idle
                    )
                }
                .padding(.horizontal, 18)
                .frame(width: 500)

               
                if vm.showHintChip {
                    HintChip(text: vm.hintText)
                        .transition(.opacity)
                        .padding(.top)
                }

                Spacer(minLength: 8)

               
                VStack(spacing: 8) {
                    Text(vm.footerText)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.65))

                    if !vm.faceOK {
                        Text("Keep your head in view")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange.opacity(0.9))
                            .transition(.opacity)
                    }

                   
                    if let t = vm.timeLeft, t <= 10, !vm.goNext {
                        Text("Auto-continue in \(t)s")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.55))
                            .transition(.opacity)
                    }
                }
                .padding(.bottom, 22)
            }
            .padding(.top, 12)
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
        .onChange(of: vm.goNext) { _, new in
            if new {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                    AudioManager.shared.playSFX(.confirm)
                    done()
                }
            }
        }
    }
}



private struct CalibrationCard: View {
    enum State { case idle, ok }

    let imageName: String
    let title: String
    let subtitle: String
    let state: State

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                    .clipped()
                    .overlay(Color.black.opacity(0.25))

                if state == .ok {
                    Text("✓")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.95))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.92)))
                        .padding(10)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.70))

                Text(subtitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .animation(.easeInOut(duration: 0.18), value: state == .ok)
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


@Observable
@MainActor
final class CalibrationGuideVM {

   
     var handOK: Bool = false
     var pinchOK: Bool = false
     var rotateOK: Bool = false
     var faceOK: Bool = false

     var cameraBlur: CGFloat = 18
     var goNext: Bool = false

  
     var timeLeft: Int? = nil

   
    @ObservationIgnored private let hand = HandMovementTracker()
   

    var session: AVCaptureSession { hand.captureSession }

    @ObservationIgnored private var started = false
    @ObservationIgnored private var hasSeenPinchDownOnce = false
    @ObservationIgnored  private var rotationBaseline: CGFloat?
    @ObservationIgnored  private var rotationAccum: CGFloat = 0

    
    @ObservationIgnored private let minRotationToPass: CGFloat = 0.25

   
    @ObservationIgnored  private let autoCompleteSeconds: Int = 20
    @ObservationIgnored  private var timeoutTask: Task<Void, Never>?
    @ObservationIgnored  private var tickTask: Task<Void, Never>?

    
    private var allowContinue: Bool { handOK && pinchOK && rotateOK && faceOK }

  
    var showHintChip: Bool { true }
    var hintText: String {
        if allowContinue { return "All set • Pinch to continue" }
        if !handOK { return "Place your hand in frame" }
        if !pinchOK { return "Pinch once to confirm" }
        if !rotateOK { return "Pinch + rotate your wrist" }
        if !faceOK { return "Keep your face in view" }
        return "Calibrating…"
    }

    var footerText: String {
        if allowContinue { return "> status: ready (pinch to continue)" }
        if !handOK { return "> input: waiting for hand" }
        if !pinchOK { return "> input: pinch not confirmed" }
        if !rotateOK { return "> input: rotation not confirmed" }
        if !faceOK { return "> input: face not detected" }
        return "> status: calibrating"
    }

    func start() {
        guard !started else { return }
        started = true

       
        startAutoCompleteCountdown()

        hand.setEyeEnabled(true)
      

        hand.onFacePresent = { [weak self] present in
            self?.faceOK = present
        }

      
        hand.onCursor = { [weak self] p in
            guard let self else { return }
            let detected = (p != nil)
            if detected != self.handOK {
                self.handOK = detected
                withAnimation(.easeInOut(duration: 0.8)) {
                    self.cameraBlur = detected ? 0 : 18
                }
            }
        }

      
        hand.onPinchChanged = { [weak self] isPinched in
            guard let self else { return }

            if isPinched{
                AudioManager.shared.playSFX(.click)
            }
            if isPinched && !self.hasSeenPinchDownOnce {
                self.hasSeenPinchDownOnce = true
                self.pinchOK = true
              
            }

         
            if isPinched && self.allowContinue {
               
                self.goNext = true
            }

           
            if !isPinched {
                self.rotationBaseline = nil
                self.rotationAccum = 0
            }
        }

        
        hand.onRotation = { [weak self] angle in
            guard let self else { return }
            guard self.hasSeenPinchDownOnce else { return }
            guard self.pinchOK else { return }

            if self.rotationBaseline == nil {
                self.rotationBaseline = angle
                return
            }
            guard let base = self.rotationBaseline else { return }

            var delta = angle - base
            while delta > .pi { delta -= 2 * .pi }
            while delta < -.pi { delta += 2 * .pi }

            self.rotationAccum = max(self.rotationAccum, abs(delta))

            if self.rotationAccum >= self.minRotationToPass {
                
                self.rotateOK = true
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.hand.updateConnectionOrientation()
            }
        }
        hand.start()
    }

    func stop() {
        timeoutTask?.cancel()
        tickTask?.cancel()
        timeoutTask = nil
        tickTask = nil

        hand.stop()
    }

  
    private func startAutoCompleteCountdown() {
        timeLeft = autoCompleteSeconds

        tickTask?.cancel()
        timeoutTask?.cancel()

     
        tickTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for t in stride(from: self.autoCompleteSeconds, through: 0, by: -1) {
                if Task.isCancelled { return }
                self.timeLeft = t
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if self.goNext { return }
            }
        }

       
        timeoutTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(self.autoCompleteSeconds) * 1_000_000_000)
            guard !Task.isCancelled else { return }
            guard !self.goNext else { return }

         
            withAnimation(.easeInOut(duration: 0.25)) {
                self.goNext = true
            }
        }
    }
}

#Preview {
    CalibrationGuideView { }
}
