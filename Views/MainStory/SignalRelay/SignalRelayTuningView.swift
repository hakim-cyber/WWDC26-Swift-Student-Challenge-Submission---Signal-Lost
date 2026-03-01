//
//  File.swift
//  SignalLost
//
//  Created by aplle on 1/16/26.
//
import SwiftUI
import AVFoundation


struct SignalRelayManualTuningView: View {
    @State private var vm = SignalRelayManualTuningVM()
    let onFinished: () -> Void

    var body: some View {
        GeometryReader { g in
            let size = g.size
            
            let maxW = size.width * 0.52
            let radarW = maxW
            let radarH = size.height * 0.16
            let dialH  = size.height * 0.30
            let dialW  = maxW * 0.70
            let panelW = maxW * 0.78
            let panelH = size.height * 0.1
            let statusBarH = size.height * 0.03
         
         
            ZStack {
                Color.black.ignoresSafeArea()

                CameraPreviewView(session: vm.session)
                    .ignoresSafeArea()
                    .opacity(0.82)
                    .blur(radius: vm.cameraBlur)
                    .overlay(Color.black.opacity(0.55))
                    .allowsHitTesting(false)

                RadialGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.80)]),
                    center: .center,
                    startRadius: 140,
                    endRadius: 980
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                VStack(spacing: 12) {

                    RelayTopStatusBar(
                        frequencyText: vm.frequencyText,
                        bars: vm.signalBars,
                        state: vm.signalState
                    )
                    .frame(maxWidth: maxW,maxHeight: statusBarH)
                    .padding(.top, 15)

                    RadarScanHeader(
                        active: !vm.didLock,
                        locked: vm.didLock,
                        intensity: vm.radarIntensity,
                        state: vm.signalState
                    )
                    .frame(width: radarW, height: radarH)
                    .padding(.top, 8)

                   

                    VStack(spacing: 8) {
                        Text(vm.primaryText)
                            .font(.system(size: 18, weight: .regular))
                            .minimumScaleFactor(0.6)
                            .foregroundStyle(.white.opacity(0.92))
                            .multilineTextAlignment(.center)

                        Text(vm.secondaryText)
                            .font(.system(size: 15, weight: .regular))
                            .minimumScaleFactor(0.6)
                            .foregroundStyle(.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                    }
                    
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: maxW,maxHeight: panelH)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.black.opacity(0.34))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(.white.opacity(0.10), lineWidth: 1)
                            )
                    )
                 
                    Spacer()

                    DialCluster(
                        dialValue: vm.dialValue,
                        stability: vm.stability,
                        proximity: vm.proximity,
                        engaged: vm.isPinched,
                        flash: vm.didLockFlash
                    )
                    .frame(width: dialW, height: dialH)
                    .padding(.horizontal, 18)

                    ReceiverPanel(
                        state: vm.signalState,
                        bars: vm.signalBars,
                        afc: vm.afcEngaged,
                        squelchAuto: true,
                        txLocked: !vm.didLock
                    )
                    .frame(width: panelW)
                    .frame(maxHeight: panelH)
                    .padding(.top, 6)

                    Spacer()

                   
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .top) {
                    VStack(spacing: 14) {
                        if vm.isPinched && vm.stability < 0.25 && !vm.didLock {
                            RotateHint()
                                .transition(.opacity)
                        }
                        Spacer()
                    }
                    .padding(.top, 48)
                }
                .opacity(vm.uiOpacity)

              
                if let c = vm.cursor {
                    CursorDot(isActive: vm.isPinched)
                        .position(x: c.x * size.width, y: c.y * size.height)
                        .allowsHitTesting(false)
                }

                if vm.showHandAlert {
                    HandMissingOverlay()
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
            }
            .onAppear {
                vm.sceneSize = size
                vm.start()
                vm.onFinished = {
                    vm.stop()
                    onFinished()
                }
            }
            .onChange(of: size) { _, new in
                vm.sceneSize = new
            }
            .onDisappear { vm.stop() }
        }
    }
}




@Observable
@MainActor
final class SignalRelayManualTuningVM {

    enum SignalState { case none, unstable, locked }

   
  var cursor: CGPoint? = nil
     var isPinched: Bool = false
     var rotation: CGFloat = 0

   
   var dialValue: CGFloat = 0.18
   var stability: CGFloat = 0.0
     var proximity: CGFloat = 0.0
     var didLockFlash: Bool = false
    var didLock: Bool = false

  
     var uiOpacity: Double = 0.0
    var cameraBlur: CGFloat = 4
    var primaryText: String = "Automatic connection failed."
     var secondaryText: String = "Pinch the dial to engage. Rotate to tune."
    var radarIntensity: Double = 0.85
     var showTip: Bool = true

   
    var signalState: SignalState = .none
    var signalBars: Int = 0
    var afcEngaged: Bool = false

   
    @ObservationIgnored   var onFinished: (() -> Void)?

   
    @ObservationIgnored  private let tracker = HandMovementTracker()
     var session: AVCaptureSession { tracker.captureSession }

    
    var sceneSize: CGSize = .zero

   
    @ObservationIgnored  private var lastAngle: CGFloat?
    @ObservationIgnored  private var started = false
    @ObservationIgnored  private var lockTriggered = false
    @ObservationIgnored  private var startTime: CFTimeInterval = 0
    @ObservationIgnored  private var autoCompleteArmed = false

    
    @ObservationIgnored  private let minMHz: CGFloat = 118.0
    @ObservationIgnored  private let maxMHz: CGFloat = 136.0

   
    @ObservationIgnored  private let gain: CGFloat = 0.85
    @ObservationIgnored  private let deadzone: CGFloat = 0.002

  
    @ObservationIgnored private let maxSessionSeconds: Double = 30.0

   
   var showHandAlert: Bool = false
    @ObservationIgnored  private var lastHandSeen: CFTimeInterval = 0
    @ObservationIgnored  private let handMissingAfter: CFTimeInterval = 0.45

    
    @ObservationIgnored  private(set) var target: CGFloat = 0.0
    @ObservationIgnored  private let targetRange: ClosedRange<CGFloat> = 0.38...0.88

   
    @ObservationIgnored  private var lastRotationTime: CFTimeInterval = 0
    @ObservationIgnored  private var rotationAccum: CGFloat = 0
    @ObservationIgnored  private let minRotationToEnableLock: CGFloat = 0.08
    @ObservationIgnored  private let rotationTimeout: CFTimeInterval = 0.45

  
    @ObservationIgnored  private var driftPhase: CGFloat = 0
    @ObservationIgnored  private var stableSince: CFTimeInterval? = nil

    @ObservationIgnored  private let captureBand: CGFloat = 0.14
    @ObservationIgnored  private let lockBand: CGFloat = 0.055
    @ObservationIgnored  private let lockHold: CFTimeInterval = 0.22

    @ObservationIgnored  private let driftSpeed: CGFloat = 0.9
    @ObservationIgnored  private let driftAmp: CGFloat = 0.020
    @ObservationIgnored  private let afcStrength: CGFloat = 0.22

   
    var frequencyMhz: CGFloat {
        minMHz + (maxMHz - minMHz) * dialValue
    }
    var targetMhz: CGFloat {
        minMHz + (maxMHz - minMHz) * target
    }
    var frequencyText: String {
        String(format: "Frequency: %.2f MHz", Double(frequencyMhz))
    }
    var tipText: String {
        "Signal Relay could not connect automatically.\nManual tuning is required to request help."
    }

  
    func start() {
        guard !started else { return }
        started = true

     
        target = CGFloat.random(in: targetRange)
        target = clamp01(target)

       
        didLockFlash = false
        didLock = false
        lockTriggered = false
        stableSince = nil
        driftPhase = 0
        rotationAccum = 0
        lastAngle = nil
        lastRotationTime = CACurrentMediaTime()

       
        primaryText = "Automatic connection failed."
        secondaryText = "Pinch the dial to engage. Rotate to tune."
        radarIntensity = 0.85
        signalState = .none
        signalBars = 0
        afcEngaged = false

     
        tracker.onCursor = { [weak self] p in
            guard let self else { return }
            self.cursor = p

            let now = CACurrentMediaTime()
            if p == nil {
                if (now - self.lastHandSeen) > self.handMissingAfter {
                    self.showHandAlert = true
                    self.afcEngaged = false
                }
            } else {
                self.lastHandSeen = now
                self.showHandAlert = false
            }
        }

        tracker.onPinchChanged = { [weak self] pinched in
            guard let self else { return }
            self.isPinched = pinched

            if pinched {
                AudioManager.shared.playSFX(.click)
                self.rotationAccum = 0
                self.stableSince = nil
                self.lastRotationTime = CACurrentMediaTime()
            } else {
                self.lastAngle = nil
                self.rotationAccum = 0
                self.stableSince = nil
            }

            withAnimation(.easeInOut(duration: 0.18)) {
                if !self.didLockFlash {
                    self.secondaryText = pinched ? "Rotate while holding." : "Pinch the dial to engage."
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

     
        startTime = CACurrentMediaTime()
        autoCompleteArmed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + maxSessionSeconds) { [weak self] in
            self?.autoCompleteIfNeeded()
        }
    }

    func stop() {
        tracker.stop()
        autoCompleteArmed = false
    }

 
    private func applyRotation(_ angle: CGFloat) {
        guard isPinched else { return }
        guard !didLockFlash else { return }

        let now = CACurrentMediaTime()

      
        guard let prev = lastAngle else {
            lastAngle = angle
            lastRotationTime = now
            return
        }

      
        var delta = angle - prev
        while delta > .pi { delta -= 2 * .pi }
        while delta < -.pi { delta += 2 * .pi }
        lastAngle = angle

      
        if abs(delta) < deadzone {
            if (now - lastRotationTime) > rotationTimeout {
               
                stability = max(0, stability - 0.04)
                proximity = max(0, proximity - 0.03)
                signalBars = max(0, signalBars - 1)
                if stability < 0.14 {
                    signalState = .none
                    afcEngaged = false
                    stableSince = nil
                    radarIntensity = 0.85
                }
            }
            return
        }

      
        lastRotationTime = now
        rotationAccum += abs(delta)

       
        dialValue = clamp01(dialValue + delta * gain)

       
        driftPhase += CGFloat(abs(delta)) * driftSpeed
        let drift = sin(driftPhase) * driftAmp
        let apparentTarget = clamp01(target + drift)

      
        let dist = abs(dialValue - apparentTarget)

        
        let p = 1 - min(1, dist / captureBand)
        proximity = clamp01(p)
        stability = clamp01(p * p * (3 - 2 * p))
        radarIntensity = 0.85 + 0.25 * Double(stability)

       
        signalBars = max(0, min(5, Int(round(5 * stability))))

        if stability < 0.18 {
            signalState = .none
            afcEngaged = false
            primaryText = "Searching…"
            secondaryText = "Rotate to tune."
            stableSince = nil
            return
        } else {
            signalState = .unstable
            primaryText = stability > 0.72 ? "Signal detected." : "Searching…"
            secondaryText = "Fine tune."
        }

       
        if dist < captureBand * 0.65 {
            afcEngaged = true
            let t = clamp01(1 - dist / (captureBand * 0.65))
            let pull = afcStrength * (0.35 + 0.65 * t)
            dialValue = clamp01(dialValue + (target - dialValue) * pull)
        } else {
            afcEngaged = false
        }

       
        if rotationAccum < minRotationToEnableLock {
            secondaryText = "Keep rotating to tune."
            stableSince = nil
            return
        }

     
        let finalDist = abs(dialValue - target)

        if finalDist < lockBand {
            if stableSince == nil { stableSince = now }
            secondaryText = "Hold… AFC locking."

            if let s = stableSince, (now - s) >= lockHold {
                dialValue = target
                proximity = 1
                stability = 1
                signalState = .locked
                signalBars = 5
                afcEngaged = true
                radarIntensity = 1.0

                if !lockTriggered {
                    lockTriggered = true
                    lockFlashAndFinish()
                }
            }
        } else {
            stableSince = nil
        }
    }

    
    private func clamp01(_ x: CGFloat) -> CGFloat { min(1, max(0, x)) }

    private func lockFlashAndFinish() {
        AudioManager.shared.playSFX(.confirm)
        didLockFlash = true
        didLock = true
        signalState = .locked
        signalBars = 5

        primaryText = "Connection established."
        secondaryText = "Transmission available."

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

    private func autoCompleteIfNeeded() {
        guard autoCompleteArmed else { return }
        guard !didLockFlash else { return }

        lockTriggered = true
        didLock = true
        dialValue = target
        proximity = 1
        stability = 1
        signalState = .locked
        signalBars = 5
        afcEngaged = true
        radarIntensity = 1.0

        lockFlashAndFinish()
    }
}


private struct RelayTopStatusBar: View {
    let frequencyText: String
    let bars: Int
    let state: SignalRelayManualTuningVM.SignalState

    private var tint: Color {
        switch state {
        case .none: return .red
        case .unstable: return .yellow
        case .locked: return .green
        }
    }

    var body: some View {
        HStack {
            Text("Signal Relay")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .minimumScaleFactor(0.5)

            Spacer()

            Text(frequencyText)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.70))
                .minimumScaleFactor(0.5)

            Spacer()

            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < bars ? tint.opacity(0.92) : .white.opacity(0.12))
                        .frame(width: 6, height: CGFloat(6 + i * 3))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: 720)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}


private struct RadarScanHeader: View {
    let active: Bool
    let locked: Bool
    let intensity: Double
    let state: SignalRelayManualTuningVM.SignalState

    @State private var sweep = false
    @State private var blip = false

    private var tint: Color {
        switch state {
        case .none: return .red
        case .unstable: return .yellow
        case .locked: return .green
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 18, x: 0, y: 12)

            ZStack {
                RadarGrid()
                    .opacity(0.35)
                    .mask(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .padding(12)
                    )

                if active {
                    RadarSweep()
                        .rotationEffect(.degrees(sweep ? 360 : 0))
                        .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: sweep)
                        .opacity(0.55 * intensity)
                        .mask(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .padding(12)
                        )
                }

              
                Group {
                    Circle().fill(.green.opacity(blip ? 0.95 : 0.22))
                        .frame(width: 10, height: 10)
                        .offset(x: -150, y: -25)

                    Circle().fill(.green.opacity(blip ? 0.85 : 0.16))
                        .frame(width: 8, height: 8)
                        .offset(x: 160, y: 20)
                }
                .opacity(active ? 1 : (locked ? 0.18 : 0))
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: blip)

                if locked {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.green.opacity(0.55), lineWidth: 1.5)
                        .blur(radius: 1.2)
                        .padding(12)
                }
            }

           
            HStack {
                Circle()
                    .fill(tint.opacity(0.95))
                    .frame(width: 8, height: 8)
                    .shadow(color: tint.opacity(0.35), radius: 10)

                Text(locked ? "LOCKED" : (active ? "SCANNING" : "IDLE"))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.78))
                    .minimumScaleFactor(0.6)

                Spacer()

                Text(locked ? "Target acquired" : "Searching nearby signals…")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .onAppear {
            sweep = true
            blip = true
        }
    }
}

private struct RadarGrid: View {
    var body: some View {
        Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 18, dy: 18)
            let center = CGPoint(x: rect.midX, y: rect.midY)

            for i in 1...4 {
                let r = min(rect.width, rect.height) * CGFloat(i) / 8.0
                let p = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r*2, height: r*2))
                ctx.stroke(p, with: .color(.green.opacity(0.22)), lineWidth: 1)
            }

            var h = Path()
            h.move(to: CGPoint(x: rect.minX, y: center.y))
            h.addLine(to: CGPoint(x: rect.maxX, y: center.y))
            h.move(to: CGPoint(x: center.x, y: rect.minY))
            h.addLine(to: CGPoint(x: center.x, y: rect.maxY))
            ctx.stroke(h, with: .color(.green.opacity(0.20)), lineWidth: 1)
        }
    }
}

private struct RadarSweep: View {
    var body: some View {
        GeometryReader { g in
            let s = g.size
            LinearGradient(
                colors: [.green.opacity(0.0), .green.opacity(0.28), .green.opacity(0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: s.width * 0.55)
            .offset(x: s.width * 0.22)
            .blur(radius: 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .blendMode(.screen)
    }
}



private struct ReceiverPanel: View {
    let state: SignalRelayManualTuningVM.SignalState
    let bars: Int
    let afc: Bool
    let squelchAuto: Bool
    let txLocked: Bool

    private var tint: Color {
        switch state {
        case .none: return .red
        case .unstable: return .yellow
        case .locked: return .green
        }
    }

    var body: some View {
        HStack(spacing: 14) {

          
            VStack(alignment: .leading, spacing: 8) {
                StatusLine(label: "AFC", value: afc ? "ENGAGED" : "OFF", tint: afc ? .green : .white.opacity(0.35))
                StatusLine(label: "SQUELCH", value: squelchAuto ? "AUTO" : "MANUAL", tint: .white.opacity(0.60))
                StatusLine(label: "TX", value: txLocked ? "LOCKED" : "READY", tint: txLocked ? .white.opacity(0.38) : .green)
            }

            Spacer()

           
            VStack(alignment: .trailing, spacing: 8) {
                Text("S-METER")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.60))
                    .minimumScaleFactor(0.6)

                HStack(spacing: 4) {
                    ForEach(0..<8, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i < (bars + 3) ? tint.opacity(0.92) : .white.opacity(0.10))
                            .frame(width: 10, height: CGFloat(8 + i * 2))
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.black.opacity(0.32))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

private struct StatusLine: View {
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 68, alignment: .leading)
                .minimumScaleFactor(0.6)

            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.6)
        }
    }
}



private struct TipCard: View {
    let title: String
    let titleBody: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.65))

            Text(titleBody)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.90))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: 720, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
        )
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
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let side = min(w, h) * 0.88

            ZStack {
                WaveformView(stability: stability)
                    .frame(height: h * 0.35)
                    .padding(.horizontal, w * 0.04)
                    .offset(y: h * 0.26)
                    .opacity(0.85)

                ZStack {
                    DialRing(engaged: engaged, flash: flash, proximity: proximity, side: side)
                    DialNotch(angle: dialAngle(dialValue), side: side)
                    DialCenter(engaged: engaged, side: side)
                }
                .frame(width: side, height: side)

                if flash {
                    RoundedRectangle(cornerRadius: side * 0.11, style: .continuous)
                        .stroke(.white.opacity(0.55), lineWidth: side * 0.05)
                        .blur(radius: side * 0.07)
                        .frame(width: w * 0.96, height: h * 0.92)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func dialAngle(_ v: CGFloat) -> Angle {
        .degrees(-140 + (280 * Double(v)))
    }
}

private struct DialRing: View {
    let engaged: Bool
    let flash: Bool
    let proximity: CGFloat
    let side: CGFloat

    @State private var pulse = false

    var body: some View {
        let p = min(1, max(0, proximity))
        let guided = engaged ? p : 0
        let glowOpacity = 0.06 + 0.30 * guided
        let glowWidth = (0.06 * side) + (0.06 * side) * guided
        let outlineOpacity = engaged ? (0.18 + 0.25 * p) : 0.16

        ZStack {
            Circle().stroke(.white.opacity(0.12), lineWidth: max(2, side * 0.04))
            Circle().stroke(.white.opacity(outlineOpacity), lineWidth: max(1.5, side * 0.008))

            Circle()
                .stroke(.white.opacity(glowOpacity), lineWidth: max(6, glowWidth))
                .blur(radius: max(6, side * 0.065))
                .opacity(engaged ? 1 : 0)
                .scaleEffect(pulse ? (1.0 + 0.02 * guided) : 1.0)

            Circle()
                .stroke(.white.opacity(flash ? 0.55 : 0.0), lineWidth: max(8, side * 0.10))
                .blur(radius: max(10, side * 0.09))
                .opacity(flash ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                pulse.toggle()
            }
        }
    }
}

private struct DialNotch: View {
    let angle: Angle
    let side: CGFloat

    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.92))
            .frame(width: max(2.5, side * 0.015), height: side * 0.11)
            .offset(y: -(side * 0.38))
            .rotationEffect(angle)
            .shadow(color: .black.opacity(0.35), radius: side * 0.04, x: 0, y: side * 0.025)
    }
}

private struct DialCenter: View {
    let engaged: Bool
    let side: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: side * 0.38, height: side * 0.38)
                .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))

            Circle()
                .fill(.white.opacity(engaged ? 0.12 : 0.08))
                .frame(width: side * 0.24, height: side * 0.24)
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

