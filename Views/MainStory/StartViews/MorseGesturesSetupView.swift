//
//  SignalLost
//
//  Created by aplle on 1/16/26.
//


import SwiftUI
import AVFoundation

struct EyeMorseOnboardingView: View {
    @State private var vm = EyeMorseOnboardingVM()

    var complete:()->Void
    var body: some View {
        ZStack {
           
            CameraPreviewView(session: vm.session)
                .ignoresSafeArea()
                .opacity(0.85)
              
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
            
            HelpOverlayCard(
                    headerIcon: "eye.trianglebadge.exclamationmark.fill",
                    headerIconColor: .cyan,
                    title: vm.step == .done ? "Eye Morse Ready" : "Eye Morse Training",
                    bodyText: """
                    Use your eyes to send an SOS when touch input is unavailable.
                    Train DOT and DASH first. Keep your face centered and well-lit.
                    """,
                    tips: morseTips(for: vm.step),
                    footerLeft: vm.faceVisible ? morseFooter(for: vm.step) : "> face not detected",
                    footerRight: "Camera Mode",
                    width: 360,
                    showsClose: false,
                    onDismiss: {  }
                )
                .padding(.top, 18)
                .padding(.trailing, 18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
           
            VStack(spacing: 28) {
                Spacer()

              
                ZStack {
                    
                    EyePulseDisc(closedAmount: vm.eyeClosedAmount)
                        .frame(width: 220, height: 220)

                  
                    if let fb = vm.feedback {
                        FeedbackSymbol(symbol: fb.symbol, style: fb.style, pulse: vm.feedbackPulse)
                            .offset(x: vm.wrongShake)
                            .transition(.opacity)
                            .frame(width: 220, height: 220)

                    }

                    Text(vm.symbolText)
                        .font(.system(size: 36, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()

               
                VStack(spacing: 10) {
                    Text(vm.primaryText)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(.white.opacity(0.95))
                        .multilineTextAlignment(.center)

                    Text(vm.secondaryText)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.black.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(.white.opacity(0.10), lineWidth: 1)
                        )
                )

             
                if !vm.faceVisible {
                    Text("Keep your head in view")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange.opacity(0.9))
                        .padding(.top, 6)
                        .transition(.opacity)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .onChange(of: vm.step, { oldValue, newValue in
            if newValue == .done{
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.complete()
                }
            }
        })
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
    private func morseFooter(for step: EyeMorseOnboardingVM.Step) -> String {
        switch step {
        case .dot:  return "> training: DOT"
        case .dash: return "> training: DASH"
        case .done: return "> ready: SOS"
        }
    }

    private func morseTips(for step: EyeMorseOnboardingVM.Step) -> [HelpOverlayCard.Tip] {
        switch step {

        case .dot:
            return [
                .init(icon: "circle.fill", text: "DOT (·): close eyes briefly, then open fully."),
                .init(icon: "viewfinder", text: "Keep both eyes visible in frame."),
                .init(icon: "lightbulb", text: "Use front light. Avoid bright window behind you."),
                .init(icon: "hand.raised", text: "Hold camera steady for 1–2 seconds.")
            ]

        case .dash:
            return [
                .init(icon: "minus", text: "DASH (—): hold eyes closed longer, then open fully."),
                .init(icon: "eye", text: "Don’t blink fast — commit to the hold."),
                .init(icon: "person.crop.square", text: "Keep head still. Don’t tilt too much."),
                .init(icon: "wave.3.right", text: "Pause between signals (open eyes).")
            ]

        case .done:
            return [
                .init(icon: "wave.3.right", text: "SOS: · · ·   — — —   · · ·"),
                .init(icon: "checkmark.seal.fill", text: "You’re calibrated. Eye control is active."),
                .init(icon: "viewfinder", text: "Best accuracy: face centered, stable lighting."),
                .init(icon: "bolt.fill", text: "If detection fails: re-center + open eyes briefly.")
            ]
        }
    }
}
private struct FeedbackSymbol: View {
    let symbol: String
    let style: EyeMorseOnboardingVM.FeedbackStyle
    let pulse: CGFloat

    var body: some View {
        let isWrong = (style == .wrong)

        ZStack {
         
            Circle()
                .stroke(isWrong ? Color.red.opacity(0.35 + 0.35 * pulse)
                                : Color.green.opacity(0.18 + 0.25 * pulse),
                        lineWidth: 18 + 10 * pulse)
                .blur(radius: 18)
                .scaleEffect(0.95 + 0.08 * pulse)

          
        }
        .allowsHitTesting(false)
    }
}
struct EyePulseDisc: View {
    let closedAmount: CGFloat

    var body: some View {
        ZStack {
            
            Circle()
                .stroke(.white.opacity(0.15), lineWidth: 10)

           
            Circle()
                .stroke(
                    .white.opacity(0.35 * closedAmount),
                    lineWidth: 16 + 14 * closedAmount
                )
                .blur(radius: 18)
                .scaleEffect(1.0 - 0.08 * closedAmount)

           
            Circle()
                .stroke(.white.opacity(0.22), lineWidth: 2)
        }
        .animation(.easeOut(duration: 0.08), value: closedAmount)
        .allowsHitTesting(false)
    }
}

@Observable
@MainActor
final class EyeMorseOnboardingVM {
    
    enum Step { case dot, dash, done }
    
    enum FeedbackStyle { case ok, wrong }
    
    struct Feedback: Equatable {
        var symbol: String
        var style: FeedbackStyle
    }
    
    var step: Step = .dot
    var primaryText = "Close your eyes briefly."
    var secondaryText = "Quick close = dot (·). Open fully after."
    var symbolText = ""
    var faceVisible = true
    var eyeClosedAmount: CGFloat = 0
    
    
    var feedback: Feedback? = nil
    var feedbackPulse: CGFloat = 0
    var wrongShake: CGFloat = 0
    
    @ObservationIgnored  let handTracker = HandMovementTracker()
  
    var session: AVCaptureSession { handTracker.captureSession }
    
    init() {
        handTracker.setEyeEnabled(true)
        handTracker.onEyeSymbol = { [weak self] symbol in
            self?.handle(symbol)
        }
        handTracker.onFacePresent = { [weak self] present in
            self?.faceVisible = present
        }
        handTracker.onEyeClosure = { [weak self] amount in
            self?.eyeClosedAmount = amount
        }
    }
    
    func start() {
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handTracker.updateConnectionOrientation()
        }
      
        handTracker.start()
        
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            await MainActor.run { self?.step = .done }
        }
    }
    
    func stop() { handTracker.stop() }
    
    @MainActor
    private func handle(_ symbol: EyeGestureHandler.EyeSymbol) {
        switch step {
        case .dot:
            if symbol == .dot {
                AudioManager.shared.playSFX(.confirm)
                accept(symbol: "·")
                symbolText = "·"
                step = .dash
                primaryText = "Now hold your eyes closed."
                secondaryText = "Longer close = dash (—). Hold steady."
            } else {
                wrong(expected: .dot, got: symbol)
            }

        case .dash:
            if symbol == .dash {
                AudioManager.shared.playSFX(.confirm)
                accept(symbol: "—")
                symbolText = "· —"
                step = .done
                primaryText = "Signal understood."
                secondaryText = "Eye control active."
            } else {
                wrong(expected: .dash, got: symbol)
            }

        case .done:
            break
        }
    }
    
    private func accept(symbol: String) {
        feedback = .init(symbol: symbol, style: .ok)
        withAnimation(.easeOut(duration: 0.18)) { feedbackPulse = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.easeInOut(duration: 0.18)) { self.feedbackPulse = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.feedback = nil
        }
    }
    
    @MainActor
    private func wrong(expected: EyeGestureHandler.EyeSymbol, got: EyeGestureHandler.EyeSymbol) {
        let gotGlyph = (got == .dot) ? "·" : "—"
        feedback = .init(symbol: gotGlyph, style: .wrong)

        AudioManager.shared.playSFX(.errorSFX)
        secondaryText = wrongMessage(expected: expected, got: got)

       
        withAnimation(.easeOut(duration: 0.16)) { feedbackPulse = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(.easeInOut(duration: 0.18)) { self.feedbackPulse = 0 }
        }

        
        withAnimation(.easeInOut(duration: 0.08)) { wrongShake = 10 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeInOut(duration: 0.08)) { self.wrongShake = -10 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.easeInOut(duration: 0.08)) { self.wrongShake = 0 }
        }

       
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            self.feedback = nil
            self.secondaryText = self.stepHintText(for: self.step)
        }
    }

    @MainActor
    private func wrongMessage(expected: EyeGestureHandler.EyeSymbol, got: EyeGestureHandler.EyeSymbol) -> String {
       
        if expected == .dot && got == .dash {
            return "Not quite—blink shorter for a dot."
        }
       
        if expected == .dash && got == .dot {
            return "Not quite—hold longer for a dash."
        }
      
        return "Not quite—try again."
    }

    @MainActor
    private func stepHintText(for step: Step) -> String {
        switch step {
        case .dot:
            return "A short close sends a dot."
        case .dash:
            return "A longer close sends a dash."
        case .done:
            return ""
        }
    }
}
