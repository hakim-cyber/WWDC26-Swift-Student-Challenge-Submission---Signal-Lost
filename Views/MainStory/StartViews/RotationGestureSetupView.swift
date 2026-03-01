//
//  SignalLost
//
//  Created by aplle on 1/16/26.
//

import Foundation
import SwiftUI
import AVFoundation

struct DialOnboardingView: View {
    @State private var vm = DialOnboardingVM()

    var completeStep:()->Void
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreviewView(session: vm.session)
                .ignoresSafeArea()
                .opacity(0.85)
                .blur(radius: 4)
                .overlay(Color.black.opacity(0.50))
                .allowsHitTesting(false)

            RadialGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.78)]),
                center: .center,
                startRadius: 130,
                endRadius: 900
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            HelpOverlayCard(
                headerIcon: "dial.high.fill",
                headerIconColor: .mint,
                title: "Tuning Dial",
                bodyText: """
                Pinch to engage the dial.
                Rotate your wrist slowly until the signal stabilizes and locks.
                """,
                tips: [
                    .init(icon:  "hand.pinch", text: "Pinch = engage (hold pinch while rotating)."),
                    .init(icon: "arrow.triangle.2.circlepath", text: "Rotate wrist gently (avoid fast spins)."),
                    .init(icon: "waveform.path.ecg", text: "Higher stability = closer to target."),
                    .init(icon: "checkmark.seal.fill", text: "When it locks, you’re done.")
                ],
                footerLeft: vm.didLockFlash ? "> locked"
                         : vm.isPinched ? (vm.stability < 0.25 ? "> rotate to stabilize" : "> stabilizing…")
                         : "> pinch to engage",
                footerRight: "Dial Mode",
                width: 360,
                showsClose: false
            )
            .padding(.top, 18)
            .padding(.trailing, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            
            VStack(spacing: 18) {
                Spacer()

                DialCluster(
                    dialValue: vm.dialValue,
                    stability: vm.stability,
                    proximity: vm.proximity,
                    engaged: vm.isPinched,
                    flash: vm.didLockFlash
                )
                .frame(width: 420, height: 360)
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 10) {
                    Text(vm.primaryText)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)

                    Text(vm.secondaryText)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.black.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(.white.opacity(0.10), lineWidth: 1)
                        )
                )
               

                Spacer(minLength: 22)
            }
            .overlay(content: {
                VStack(spacing: 18) {
                    
                    if vm.isPinched && vm.stability < 0.25 {
                        RotateHint()
                        
                            .transition(.opacity)
                    }
                    
                    Spacer()
                }
                .padding(.top,50)
                
            })
            .opacity(vm.uiOpacity)
            
        }
        .onAppear {
            vm.start()
            vm.onFinished = {
                self.completeStep()
            }
        }
        .onDisappear { vm.stop() }
        
    }
}
private struct RotateHint: View {
    @State private var wiggle = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))

            Text("Rotate your wrist")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.black.opacity(0.25))
                .overlay(Capsule().stroke(.white.opacity(0.10), lineWidth: 1))
        )
        .rotationEffect(.degrees(wiggle ? 10 : -10))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                wiggle.toggle()
            }
        }
        .allowsHitTesting(false)
    }
}


private struct DialCluster: View {
    let dialValue: CGFloat
    let stability: CGFloat
    let proximity: CGFloat
    let engaged: Bool
    let flash: Bool

    var body: some View {
        ZStack {
            WaveformView(stability: stability)
                .frame(height: 120)
                .padding(.horizontal, 10)
                .offset(y: 90)
                .opacity(0.85)

            ZStack {
                DialRing(engaged: engaged, flash: flash, proximity: proximity)
                DialNotch(angle: dialAngle(dialValue))
                    .animation(.easeOut(duration: 0.10), value: dialValue)
                DialCenter(engaged: engaged)
            }
            .frame(width: 240, height: 240)

            if flash {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.55), lineWidth: 12)
                    .blur(radius: 18)
                    .frame(width: 320, height: 280)
                    .transition(.opacity)
            }
        }
    }

    private func dialAngle(_ v: CGFloat) -> Angle {
        let start: Double = -140
        let end: Double = 140
        let deg = start + (end - start) * Double(v)
        return .degrees(deg)
    }
}

private struct DialRing: View {
    let engaged: Bool
    let flash: Bool
    let proximity: CGFloat

    @State private var pulse = false

    var body: some View {
        let p = clamp01(proximity)
        let guided = engaged ? p : 0
        let glowOpacity = 0.06 + 0.30 * guided
        let glowWidth: CGFloat = 14 + 14 * guided
        let outlineOpacity = engaged ? (0.18 + 0.25 * p) : 0.16

        ZStack {
      
            Circle()
                .stroke(.white.opacity(0.12), lineWidth: 10)

          
            Circle()
                .stroke(.white.opacity(outlineOpacity), lineWidth: 2)

         
            Circle()
                .stroke(.white.opacity(glowOpacity), lineWidth: glowWidth)
                .blur(radius: 16)
                .opacity(engaged ? 1 : 0)
                .scaleEffect(pulse ? (1.0 + 0.02 * guided) : 1.0)

          
            Circle()
                .stroke(.white.opacity(flash ? 0.55 : 0.0), lineWidth: 24)
                .blur(radius: 22)
                .opacity(flash ? 1 : 0)
        }
        .onAppear {
         
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                pulse.toggle()
            }
        }
        .animation(.easeInOut(duration: 0.18), value: engaged)
        .animation(.easeOut(duration: 0.20), value: flash)
        .animation(.easeInOut(duration: 0.12), value: proximity)
    }

    private func clamp01(_ x: CGFloat) -> CGFloat { min(1, max(0, x)) }
}

private struct DialNotch: View {
    let angle: Angle
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.92))
            .frame(width: 4, height: 26)
            .offset(y: -92)
            .rotationEffect(angle)
            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
    }
}

private struct DialCenter: View {
    let engaged: Bool
    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 88, height: 88)
                .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))

            Circle()
                .fill(.white.opacity(engaged ? 0.12 : 0.08))
                .frame(width: 56, height: 56)
        }
        .animation(.easeInOut(duration: 0.18), value: engaged)
    }
}

private struct WaveformView: View {
    let stability: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let midY = size.height * 0.5
            let ampMax = size.height * 0.32
            let noise = (1 - stability)

            var path = Path()
            path.move(to: CGPoint(x: 0, y: midY))

            let steps = 90
            for i in 0...steps {
                let x = size.width * CGFloat(i) / CGFloat(steps)
                let base = sin(CGFloat(i) * 0.22) * (ampMax * 0.35)
                let jitter = (sin(CGFloat(i) * 1.7) + cos(CGFloat(i) * 2.3)) * (ampMax * 0.55) * noise
                path.addLine(to: CGPoint(x: x, y: midY + base + jitter))
            }

            ctx.stroke(path, with: .color(.white.opacity(0.55)), lineWidth: 2)
            ctx.stroke(path, with: .color(.white.opacity(0.10)), lineWidth: 10)
        }
        .blur(radius: 0.4)
    }
}


@Observable
@MainActor
final class DialOnboardingVM {

   
     var cursor: CGPoint? = nil
     var isPinched: Bool = false
     var rotation: CGFloat = 0
     var proximity: CGFloat = 0
   
     var dialValue: CGFloat = 0.18
     var stability: CGFloat = 0.0
     var didLockFlash: Bool = false

   
     var primaryText: String = "Rotate to adjust."
     var secondaryText: String = "Pinch to engage."

   
     var uiOpacity: Double = 0.0
     var cameraOpacity: Double = 1.0
     var cameraBlur: CGFloat = 4

   
    @ObservationIgnored var onFinished: (() -> Void)?

    @ObservationIgnored  private let tracker = HandMovementTracker()
    var session: AVCaptureSession { tracker.captureSession }

    @ObservationIgnored  private var lastAngle: CGFloat?
    @ObservationIgnored  private var started = false
    @ObservationIgnored  private var lockTriggered = false

    
    @ObservationIgnored  private let gain: CGFloat = 0.85
    @ObservationIgnored private let target: CGFloat = 0.72
    @ObservationIgnored private let lockThreshold: CGFloat = 0.92
    @ObservationIgnored private let deadzone: CGFloat = 0.002
    
    @ObservationIgnored private let magnetStart: CGFloat = 0.18
    @ObservationIgnored private let magnetFull: CGFloat  = 0.04
    @ObservationIgnored private let snapWindow: CGFloat  = 0.012
    @ObservationIgnored private let magnetStrength: CGFloat = 0.10
    
    @ObservationIgnored private var autoFinishTask: Task<Void, Never>?
    func start() {
        guard !started else { return }
        started = true

       
        tracker.onCursor = { [weak self] p in
            self?.cursor = p
        }
        tracker.onPinchChanged = { [weak self] pinched in
            guard let self else { return }
            self.isPinched = pinched
            if !pinched { self.lastAngle = nil }
            withAnimation(.easeInOut(duration: 0.18)) {
                if !self.didLockFlash {
                    if pinched{
                        AudioManager.shared.playSFX(.click)
                    }
                    self.secondaryText = pinched ? "Rotate while holding." : "Pinch to engage."
                }
            }
        }

      
        tracker.onRotation = { [weak self] angle in
            guard let self else { return }
            self.rotation = angle
            self.applyRotation(angle)
        }
        
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.tracker.updateConnectionOrientation()
        }
        
        tracker.start()

     
        withAnimation(.easeInOut(duration: 0.6)) { uiOpacity = 1.0 }

        autoFinishTask = Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 30_000_000_000)
                    if Task.isCancelled { return }
                    await MainActor.run {
                        self?.onFinished?()
                        print("finished")
                    }
                }
        
    }

    func stop() {
           autoFinishTask?.cancel()
           autoFinishTask = nil
           tracker.stop()
       }

    private func applyRotation(_ angle: CGFloat) {
        guard isPinched else { return }
        guard !didLockFlash else { return }

        guard let prev = lastAngle else {
            lastAngle = angle
            return
        }

       
        var delta = angle - prev
        while delta > .pi { delta -= 2 * .pi }
        while delta < -.pi { delta += 2 * .pi }
        lastAngle = angle

       
        if abs(delta) < deadzone { return }

       
        let newValue = dialValue + delta * gain
        dialValue = min(1, max(0, newValue))

       
       
        
       
        var dist = abs(dialValue - target)

       
        proximity = 1 - min(1, dist / magnetStart)

        
        if dist < magnetStart {
            let t = min(1, max(0, (magnetStart - dist) / (magnetStart - magnetFull)))
            let eased = t * t * (3 - 2 * t) 
            dialValue += (target - dialValue) * (magnetStrength * eased)
            dialValue = min(1, max(0, dialValue))
        }

       
        dist = abs(dialValue - target)

      
        if dist < snapWindow {
            dialValue = target
            dist = 0
        }

      
        let normalized = min(1, dist / magnetStart)
        let ease = 1 - (normalized * normalized)
        stability = min(1, max(0, ease))

    
       
        if stability > 0.85 {
            primaryText = "Signal stabilizing."
        } else {
            primaryText = "Rotate to adjust."
        }

      
        if !lockTriggered, stability >= lockThreshold {
            lockTriggered = true
            lockFlashAndFinish()
        }
    }

    private func lockFlashAndFinish() {
        AudioManager.shared.playSFX(.confirm)
        didLockFlash = true
        secondaryText = "Locked."
        withAnimation(.easeInOut(duration: 0.18)) {
            cameraBlur = 1
        }

        

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }
            withAnimation(.easeInOut(duration: 0.45)) {
                self.uiOpacity = 0.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.onFinished?()
        }
    }
}
