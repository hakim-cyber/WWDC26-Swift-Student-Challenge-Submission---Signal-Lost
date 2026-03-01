//
//  EyeMorseFinalView.swift
//  SignalLost
//
//  Created by aplle on 1/28/26.
//

import SwiftUI
import AVFoundation
import AudioToolbox


struct EyeMorseFinalView: View {
    @State private var vm = EyeMorseFinalVM()
    var onFinished: () -> Void

    var body: some View {
        ZStack {

          
            CameraPreviewView(session: vm.session)
                .ignoresSafeArea()
                .blur(radius: vm.cameraBlur)
                .overlay(Color.black.opacity(0.55))
                .allowsHitTesting(false)

            RadialGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.88)]),
                center: .center,
                startRadius: 130,
                endRadius: 980
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

          
            VStack(spacing: 0) {
              
                HStack(alignment: .top) {
                    CameraMetaOverlay(
                        cameraLabel: "FRONT",
                        fpsText: vm.fpsText,
                        fpsStable: vm.fpsStable,
                        lowLightOn: true
                    )

                    Spacer()

                    TransmissionTimeline(stage: vm.txStage, encodePulsing: vm.encodePulsing)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
               
                EyeCirclesRow(
                    leftClosed: vm.leftEyeClosed,
                    rightClosed: vm.rightEyeClosed,
                    leftGlow: vm.leftGlow,
                    rightGlow: vm.rightGlow,
                    merge: vm.mergeRing,
                    pulse: vm.completionPulse
                )
                .frame(height: 140)
                .padding(.top, 12)
                .offset(x: vm.wrongShake)


               

              
                MorseProgressRow(
                    slots: vm.slots,
                    activeIndex: vm.activeSlotIndex,
                    dashStretch: vm.dashStretch,
                    softPulse: vm.softPulse
                )
                .frame(width: 520, height: 40)
                .padding(.top, 10)
                .opacity(vm.phase == .sending ? 1.0 : 0.35)

                if vm.showFaceWarning {
                    Text("Keep your face in view")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.orange.opacity(0.92))
                        .padding(.top, 8)
                        .transition(.opacity)
                }
                
                VStack(spacing: 10) {
                    Text(vm.headline)
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.white.opacity(0.95))
                        .multilineTextAlignment(.center)

                
                    if !vm.finalLine1.isEmpty {
                        Text(vm.finalLine1)
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.86))
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }

                    if !vm.finalLine2.isEmpty {
                        Text(vm.finalLine2)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.white.opacity(0.70))
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }

                  
                    if vm.phase == .sending {
                        Text(vm.instruction)
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.82))
                            .multilineTextAlignment(.center)

                        Text(vm.hint)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.white.opacity(0.62))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 34)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.black.opacity(0.32))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(.white.opacity(0.10), lineWidth: 1)
                        )
                )
                .animation(.easeInOut(duration: 0.20), value: vm.instruction)
                .animation(.easeInOut(duration: 0.20), value: vm.finalLine1)
                .animation(.easeInOut(duration: 0.20), value: vm.finalLine2)

               

                Spacer(minLength: 34)
            }
            .opacity(vm.uiOpacity)

        
            Color.black
                .ignoresSafeArea()
                .opacity(vm.blackoutOpacity)
                .allowsHitTesting(vm.inputLocked || vm.blackoutOpacity > 0.01)
        }
        .contentShape(Rectangle())
        .allowsHitTesting(!vm.inputLocked)
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
        .onChange(of: vm.phase) { _, new in
            if new == .exiting {
                vm.stop()
                onFinished()
            }
        }
    }
}

@Observable
@MainActor
final class EyeMorseFinalVM {

   
    enum Phase { case sending, transmitted, exiting }
    enum TxStage: Int { case capture = 0, encode = 1, transmit = 2 }

  
    struct Slot: Identifiable, Equatable {
        enum Kind { case dot, dash }
        let id = UUID()
        let kind: Kind
        var filled: Bool
        var locked: Bool
    }

    var phase: Phase = .sending
     var inputLocked: Bool = false

    var uiOpacity: Double = 1.0
     var blackoutOpacity: Double = 0.0
    var cameraBlur: CGFloat = 3.5

   
     var shimmerStrength: CGFloat = 0.55

   
     var leftEyeClosed: CGFloat = 0
    var rightEyeClosed: CGFloat = 0
     var leftGlow: CGFloat = 0
     var rightGlow: CGFloat = 0

    
     var mergeRing: CGFloat = 0
     var completionPulse: CGFloat = 0

   
    var headline: String = "Send emergency signal"
     var instruction: String = "Short blink"
     var hint: String = "Close briefly to send a dot."
     var showFaceWarning: Bool = false

   
     var finalLine1: String = ""
     var finalLine2: String = ""

   
   var slots: [Slot] = []
     var activeSlotIndex: Int = 0
     var dashStretch: CGFloat = 0
     var softPulse: CGFloat = 0
     var wrongShake: CGFloat = 0

   
     var txStage: TxStage = .capture
     var encodePulsing: Bool = false

   
     var fpsText: String = "—"
     var fpsStable: Bool = true

  
    @ObservationIgnored let handTracker = HandMovementTracker()
   
    var session: AVCaptureSession { handTracker.captureSession }

    
    @ObservationIgnored  private var started = false

    @ObservationIgnored  private var lastFpsTS: CMTime?
    @ObservationIgnored private var fpsEMA: Double = 0
    @ObservationIgnored private let fpsAlpha = 0.12

   
    enum Step: Int, CaseIterable {
        case s1 = 0, s2, s3
        case o1, o2, o3
        case s4, s5, s6
        case done
    }
     private(set) var step: Step = .s1

   
    @ObservationIgnored private var isInAutoPause: Bool = false
    @ObservationIgnored  private let autoPauseDuration: CFTimeInterval = 0.55
    @ObservationIgnored  private var autoPauseToken: Int = 0

    init() {
       
        slots = [
            .init(kind: .dot,  filled: false, locked: false),
            .init(kind: .dot,  filled: false, locked: false),
            .init(kind: .dot,  filled: false, locked: false),

            .init(kind: .dash, filled: false, locked: false),
            .init(kind: .dash, filled: false, locked: false),
            .init(kind: .dash, filled: false, locked: false),

            .init(kind: .dot,  filled: false, locked: false),
            .init(kind: .dot,  filled: false, locked: false),
            .init(kind: .dot,  filled: false, locked: false),
        ]
        
        handTracker.setEyeEnabled(true)

        handTracker.onEyeSymbol = { [weak self] sym in
            guard let self else { return }
            Task { @MainActor in self.handle(sym) }
        }

        handTracker.onFacePresent = { [weak self] present in
            guard let self else { return }
            Task { @MainActor in self.showFaceWarning = !present }
        }

       
        handTracker.onEyeClosure = { [weak self] amount in
            guard let self else { return }
            Task { @MainActor in
                self.leftEyeClosed = amount
                self.rightEyeClosed = amount

                let closing = amount > 0.62
                if closing {
                    self.leftGlow = min(1, self.leftGlow + 0.06)
                    self.rightGlow = min(1, self.rightGlow + 0.06)
                } else {
                    self.leftGlow = max(0, self.leftGlow - 0.10)
                    self.rightGlow = max(0, self.rightGlow - 0.10)
                }
            }
        }
    }

    func start() {
        guard !started else { return }
        started = true

        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handTracker.updateConnectionOrientation()
        }

       

        handTracker.start()
        syncInstruction()

        withAnimation(.easeInOut(duration: 0.35)) {
            uiOpacity = 1.0
            blackoutOpacity = 0.0
        }
    }

    func stop() {
        handTracker.onEyeSymbol = nil
        handTracker.onEyeClosure = nil
        handTracker.onFacePresent = nil
        handTracker.onCursor = nil
        handTracker.onPinchChanged = nil
        handTracker.onClick = nil
        handTracker.onRotation = nil
        handTracker.stop()
    }

   

    private func expectedKind(for step: Step) -> Slot.Kind? {
        switch step {
        case .s1, .s2, .s3, .s4, .s5, .s6: return .dot
        case .o1, .o2, .o3: return .dash
        case .done: return nil
        }
    }

    private func slotIndex(for step: Step) -> Int? {
        switch step {
        case .s1: return 0
        case .s2: return 1
        case .s3: return 2
        case .o1: return 3
        case .o2: return 4
        case .o3: return 5
        case .s4: return 6
        case .s5: return 7
        case .s6: return 8
        case .done: return nil
        }
    }

    private func handle(_ symbol: EyeGestureHandler.EyeSymbol) {
        guard phase == .sending else { return }
        guard inputLocked == false else { return }
        guard !isInAutoPause else { return }

        guard let need = expectedKind(for: step) else { return }
        let got: Slot.Kind = (symbol == .dot) ? .dot : .dash

        if got == need {
            if got == .dot{
                AudioManager.shared.playDot()
            }else{
                AudioManager.shared.playDash()
            }
            userActed()

           
            if let i = slotIndex(for: step), i < slots.count {
                slots[i].filled = true
                slots[i].locked = true
                activeSlotIndex = min(i + 1, max(0, slots.count - 1))
                softPulseBump()
            }

           
            if got == .dash {
                withAnimation(.easeOut(duration: 0.10)) { dashStretch = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.easeInOut(duration: 0.14)) { self.dashStretch = 0 }
                }
            }

            advanceStep()
        } else {
            wrongFeedback()
        }
    }

    private func userActed() {
      
        if txStage == .capture { txStage = .encode }
    }

    private func advanceStep() {
        switch step {
        case .s1: step = .s2
        case .s2: step = .s3
        case .s3:
            step = .o1
            beginAutoPauseEncodePulse()

        case .o1: step = .o2
        case .o2: step = .o3
        case .o3:
            step = .s4
            beginAutoPauseEncodePulse()

        case .s4: step = .s5
        case .s5: step = .s6
        case .s6:
            step = .done
            completeSOS()

        case .done:
            break
        }

        syncInstruction()
    }

    private func beginAutoPauseEncodePulse() {
        isInAutoPause = true
        autoPauseToken &+= 1
        let token = autoPauseToken

        txStage = .encode
        encodePulsing = true

        headline = "Send emergency signal"
        instruction = "Processing…"
        hint = "Hold steady."

        withAnimation(.easeInOut(duration: 0.25)) {
            shimmerStrength = 0.35
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + autoPauseDuration) { [weak self] in
            guard let self else { return }
            guard self.autoPauseToken == token else { return }

            self.isInAutoPause = false
            self.encodePulsing = false

            withAnimation(.easeInOut(duration: 0.25)) {
                self.shimmerStrength = 0.55
            }

            self.syncInstruction()
        }
    }

    private func syncInstruction() {
        guard phase == .sending else {
            if phase == .transmitted {
                txStage = .transmit
                encodePulsing = false
            }
            return
        }

        if isInAutoPause { return }

        switch step {
        case .s1, .s2, .s3, .s4, .s5, .s6:
            headline = "Send emergency signal"
            instruction = "Short blink"
            hint = "Close briefly to send a dot."
            txStage = (txStage == .capture) ? .capture : .encode

        case .o1, .o2, .o3:
            headline = "Send emergency signal"
            instruction = "Long blink"
            hint = "Hold closed longer to send a dash."
            txStage = .encode

        case .done:
            txStage = .transmit
        }

        if let idx = slots.firstIndex(where: { !$0.filled }) {
            activeSlotIndex = idx
        } else {
            activeSlotIndex = max(0, slots.count - 1)
        }
    }

    @MainActor
   
   

   
    private func completeSOS() {
        Task { @MainActor in
          
            await playSOS()

          
            AudioManager.shared.playSFX(.confirm)

          
            txStage = .transmit
            encodePulsing = false
            phase = .transmitted
            inputLocked = true
            isInAutoPause = true

            withAnimation(.easeInOut(duration: 0.35)) {
                uiOpacity = 0.72
                cameraBlur = 1.0
                shimmerStrength = 0.22
            }

            
            withAnimation(.easeInOut(duration: 0.55)) { mergeRing = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.easeOut(duration: 0.55)) { self.completionPulse = 1.0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                withAnimation(.easeInOut(duration: 0.35)) { self.completionPulse = 0.0 }
            }

         
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                self.headline = "Emergency signal"
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.finalLine1 = "Emergency transmission complete"
                    self.finalLine2 = ""
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.finalLine2 = "System will notify when a response is received"
                }
            }

           
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation(.easeInOut(duration: 0.70)) {
                    self.blackoutOpacity = 1.0
                }
            }

          
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.05) {
                AudioManager.shared.playSFX(.whoosh,volume: 0.5)
            }

           
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.50) {
                self.phase = .exiting
            }
        }
    }
    func playSOS() async {
        let unit: UInt64 = 120_000_000
        let letterGap: UInt64 = unit * 3

        
        AudioManager.shared.playDot()
        try? await Task.sleep(nanoseconds: 300_000_000 + unit)
        AudioManager.shared.playDot()
        try? await Task.sleep(nanoseconds: 300_000_000 + unit)
        AudioManager.shared.playDot()
        try? await Task.sleep(nanoseconds: 300_000_000 + letterGap)

       
        AudioManager.shared.playDash()
        try? await Task.sleep(nanoseconds: 600_000_000 + unit)
        AudioManager.shared.playDash()
        try? await Task.sleep(nanoseconds: 600_000_000 + unit)
        AudioManager.shared.playDash()
        try? await Task.sleep(nanoseconds: 600_000_000 + letterGap)

      
        AudioManager.shared.playDot()
        try? await Task.sleep(nanoseconds: 300_000_000 + unit)
        AudioManager.shared.playDot()
        try? await Task.sleep(nanoseconds: 300_000_000 + unit)
        AudioManager.shared.playDot()
        try? await Task.sleep(nanoseconds: 200_000_000 + unit)
    }

   

    private func softPulseBump() {
        withAnimation(.easeOut(duration: 0.16)) { softPulse = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(.easeInOut(duration: 0.20)) { self.softPulse = 0 }
        }
    }

    private func wrongFeedback() {
        withAnimation(.easeInOut(duration: 0.08)) { wrongShake = 10 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeInOut(duration: 0.08)) { self.wrongShake = -10 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.easeInOut(duration: 0.08)) { self.wrongShake = 0 }
        }
    }

  

    private func updateFPS(from buffer: CMSampleBuffer) {
        let ts = CMSampleBufferGetPresentationTimeStamp(buffer)
        guard ts.isValid else { return }

        if let last = lastFpsTS {
            let dt = CMTimeGetSeconds(ts - last)
            if dt > 0.0001 {
                let inst = 1.0 / dt
                fpsEMA = fpsEMA == 0 ? inst : (fpsEMA + fpsAlpha * (inst - fpsEMA))

                let rounded = Int((fpsEMA).rounded())
                Task { @MainActor in
                    self.fpsText = "\(max(1, rounded)) FPS"
                    self.fpsStable = (rounded >= 24 && rounded <= 66)
                }
            }
        }
        lastFpsTS = ts
    }
}


private struct TransmissionTimeline: View {
    let stage: EyeMorseFinalVM.TxStage
    let encodePulsing: Bool

    var body: some View {
        HStack(spacing: 10) {
            StagePill(title: "CAPTURE", active: stage.rawValue >= 0, strong: stage == .capture, pulsing: false)
            Chevron()
            StagePill(title: "ENCODE",  active: stage.rawValue >= 1, strong: stage == .encode, pulsing: encodePulsing)
            Chevron()
            StagePill(title: "TRANSMIT",active: stage.rawValue >= 2, strong: stage == .transmit, pulsing: false)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.black.opacity(0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

private struct StagePill: View {
    let title: String
    let active: Bool
    let strong: Bool
    let pulsing: Bool

    @State private var pulse = false

    var body: some View {
        let a = active ? 0.92 : 0.35
        let glow = strong ? 0.22 : (active ? 0.10 : 0.0)
        let pulseScale = pulsing ? (pulse ? 1.06 : 0.98) : 1.0
        let pulseGlow  = pulsing ? (pulse ? 0.28 : 0.12) : glow

        Text(title)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(a))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.white.opacity(active ? 0.08 : 0.03))
                    .overlay(Capsule().stroke(.white.opacity(active ? 0.12 : 0.08), lineWidth: 1))
            )
            .overlay(
                Capsule()
                    .stroke(.white.opacity(pulseGlow), lineWidth: 10)
                    .blur(radius: 14)
                    .opacity(active ? 1 : 0)
            )
            .scaleEffect(pulseScale)
            .animation(.easeInOut(duration: 0.18), value: active)
            .animation(.easeInOut(duration: 0.18), value: strong)
            .onChange(of: pulsing) { _, new in
                if new {
                    withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                } else {
                    pulse = false
                }
            }
            .onAppear {
                if pulsing {
                    withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                }
            }
    }
}

private struct Chevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white.opacity(0.35))
    }
}


private struct CameraMetaOverlay: View {
    let cameraLabel: String
    let fpsText: String
    let fpsStable: Bool
    let lowLightOn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            MetaLine(label: "CAMERA", value: cameraLabel)
            MetaLine(label: "FRAME RATE", value: fpsStable ? "STABLE" : "ADAPTING")
            MetaLine(label: "LOW-LIGHT", value: lowLightOn ? "COMPENSATION: ON" : "COMPENSATION: OFF")
        }
        .font(.system(size: 11, weight: .bold, design: .monospaced))
        .foregroundStyle(.white.opacity(0.70))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.black.opacity(0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
        )
        .overlay(alignment: .topTrailing) {
            Text(fpsText)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.trailing, 10)
                .padding(.top, 10)
        }
    }
}

private struct MetaLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Text(label + ":")
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .foregroundStyle(.white.opacity(0.78))
        }
    }
}




private struct MorseProgressRow: View {
    let slots: [EyeMorseFinalVM.Slot]
    let activeIndex: Int
    let dashStretch: CGFloat
    let softPulse: CGFloat

    var body: some View {
        ZStack {
      
            HStack(spacing: 10) {
                ForEach(Array(slots.enumerated()), id: \.element.id) { idx, s in
                    MorseSlotPill(
                        kind: s.kind,
                        filled: s.filled,
                        locked: s.locked,
                        isActive: idx == activeIndex,
                        dashStretch: (idx == activeIndex && s.kind == .dash) ? dashStretch : 0,
                        softPulse: softPulse
                    )
                }
            }
            .padding(.horizontal, 10)
        }
        .allowsHitTesting(false)
    }
}

private struct MorseSlotPill: View {
    let kind: EyeMorseFinalVM.Slot.Kind
    let filled: Bool
    let locked: Bool
    let isActive: Bool
    let dashStretch: CGFloat
    let softPulse: CGFloat

    var body: some View {
        switch kind {
        case .dot:
            Circle()
                .fill(filled ? .white.opacity(0.92) : .white.opacity(0.18))
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(locked ? 0.28 : 0.10), lineWidth: 10)
                        .blur(radius: 14)
                        .opacity(locked ? (0.20 + 0.25 * softPulse) : 0)
                )
                .scaleEffect(isActive ? 1.12 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: filled)
                .animation(.easeInOut(duration: 0.15), value: isActive)

        case .dash:
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(filled ? .white.opacity(0.92) : .white.opacity(0.18))
                .frame(width: 28, height: 8)
                .scaleEffect(x: 1.0 + 0.85 * dashStretch, y: 1.0, anchor: .center)
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(.white.opacity(locked ? 0.28 : 0.10), lineWidth: 10)
                        .blur(radius: 14)
                        .opacity(locked ? (0.18 + 0.25 * softPulse) : 0)
                )
                .scaleEffect(isActive ? 1.06 : 1.0)
                .animation(.easeOut(duration: 0.10), value: dashStretch)
                .animation(.easeInOut(duration: 0.15), value: filled)
                .animation(.easeInOut(duration: 0.15), value: isActive)
        }
    }
}


private struct EyeCirclesRow: View {
    let leftClosed: CGFloat
    let rightClosed: CGFloat
    let leftGlow: CGFloat
    let rightGlow: CGFloat
    let merge: CGFloat
    let pulse: CGFloat

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let center = CGPoint(x: w * 0.5, y: h * 0.5)

           
            let sep: CGFloat = min(120, w * 0.22)
            let leftPos = CGPoint(x: center.x - sep * (1 - merge), y: center.y)
            let rightPos = CGPoint(x: center.x + sep * (1 - merge), y: center.y)

          
            let base: CGFloat = 92
            let lScale = 1.0 - 0.32 * leftClosed
            let rScale = 1.0 - 0.32 * rightClosed

            ZStack {
                EyeStateCircle(closed: leftClosed, glow: leftGlow, merge: merge, pulse: pulse)
                    .frame(width: base, height: base)
                    .scaleEffect(lScale)
                    .position(leftPos)

                EyeStateCircle(closed: rightClosed, glow: rightGlow, merge: merge, pulse: pulse)
                    .frame(width: base, height: base)
                    .scaleEffect(rScale)
                    .position(rightPos)

              
                if merge > 0.02 {
                    CompletionRing(pulse: pulse)
                        .opacity(merge)
                        .position(center)
                }
            }
            .animation(.easeInOut(duration: 0.22), value: merge)
            .animation(.easeOut(duration: 0.10), value: leftClosed)
            .animation(.easeOut(duration: 0.10), value: rightClosed)
        }
    }
}

private struct EyeStateCircle: View {
    let closed: CGFloat
    let glow: CGFloat
    let merge: CGFloat
    let pulse: CGFloat  

    var body: some View {
        ZStack {
           
            Circle()
                .stroke(.white.opacity(0.18), lineWidth: 10)

           
            Circle()
                .stroke(.white.opacity(0.22), lineWidth: 2)

          
            Circle()
                .stroke(.white.opacity(0.12 + 0.28 * glow), lineWidth: 14 + 16 * glow)
                .blur(radius: 18)
                .scaleEffect(1.0 - 0.06 * closed)

           
            Circle()
                .stroke(.white.opacity(0.10 + 0.18 * (1 - merge)), lineWidth: 18)
                .blur(radius: 22)
                .opacity(0.25)
                .scaleEffect(1.0 + 0.03 * pulse)
        }
        .allowsHitTesting(false)
    }
}

private struct CompletionRing: View {
    let pulse: CGFloat 

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.10), lineWidth: 2)

            Circle()
                .stroke(.white.opacity(0.45), lineWidth: 2.5)
                .blur(radius: 0.8)

          
            Circle()
                .stroke(.white.opacity(0.25 * (1 - pulse)), lineWidth: 10 + 16 * pulse)
                .blur(radius: 18)
                .scaleEffect(1.0 + 0.35 * pulse)
                .opacity(pulse > 0 ? 1 : 0)
        }
        .frame(width: 140, height: 140)
        .allowsHitTesting(false)
    }
}

