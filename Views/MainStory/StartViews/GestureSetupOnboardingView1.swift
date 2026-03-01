//
//  SignalLost
//
//  Created by aplle on 1/16/26.
//


import SwiftUI
import AVFoundation



struct GestureSetupOnboardingView: View {
    @State private var vm = GestureSetupOnboardingVM()

    var completeStep:()->Void
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

          
            CameraPreviewView(session: vm.session)
                .ignoresSafeArea()
                .opacity(vm.cameraOpacity)
                .blur(radius: vm.cameraBlur)
                .overlay(Color.black.opacity(0.35))
                .allowsHitTesting(false)

           
            RadialGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.65)]),
                center: .center,
                startRadius: 120,
                endRadius: 900
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

          
            GeometryReader { geo in
                ZStack {
                   
                    ForEach(vm.balloons) { b in
                        BalloonView(balloon: b,
                                   isHovering: vm.isCursorInsideBalloon(b, in: geo.size),
                                   isPopped: vm.poppedIDs.contains(b.id))
                        .position(vm.balloonPosition(b, in: geo.size))
                        .opacity(vm.poppedIDs.contains(b.id) ? 0 : 1)
                        .animation(.easeInOut(duration: 0.18), value: vm.poppedIDs)
                    }

                   
                    if let c = vm.cursorNormalized {
                        CursorDot(isActive: vm.isPinched)
                            .position(
                                x: c.x * geo.size.width,
                                y: c.y * geo.size.height
                            )
                          
                    }
                }
                .onChange(of: vm.clicks) { _, _ in
                   
                    vm.tryPop(in: geo.size)
                }
                .onAppear {
                    vm.setSceneSize(geo.size)
                }
                .onChange(of: geo.size) { _, newSize in
                    vm.setSceneSize(newSize)
                }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    LoopingGestureVideo(name: "pinch")
                        .frame(width: 150, height: 150)
                       
                       
                }
                .padding(.trailing,38)
                .padding(.bottom, 42)
            }
            
            HelpOverlayCard(
                headerIcon: "hand.raised.fill",
                headerIconColor: .cyan,
                title: "Gesture Setup",
                bodyText: """
                This trains the core gesture: move cursor + pinch to interact.
                Pop 3 targets to confirm tracking is stable.
                """,
                tips: [
                    .init(icon: "viewfinder", text: "Keep your hand fully in frame."),
                    .init(icon: "lightbulb", text: "Use front lighting (avoid backlight)."),
                    .init(icon: "dot.circle", text: "Move the cursor onto a balloon."),
                    .init(icon: "hand.pinch", text: "Pinch = tap (pops the balloon).")
                ],
                footerLeft: (vm.cursorNormalized == nil) ? "> no hand detected" : "> aim + pinch to pop",
                footerRight: "Gesture Mode",
                width: 360,
                showsClose: false
            )
            .padding(.top, 18)
            .padding(.trailing, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            
            
            VStack {
                   
                Text("GESTURE SETUP")
                    .font(.system(size: 12, weight: .semibold, design: .default))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .padding(.top, 18)
                    .opacity(vm.uiTextOpacity)

                Spacer()

             
                VStack(spacing: 10) {
                    Text(vm.primaryLine)
                        .font(.system(size: 26, weight: .regular, design: .default))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .multilineTextAlignment(.center)

                    Text(vm.secondaryLine)
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                )
                .opacity(vm.uiTextOpacity)

                Spacer()

               
                HStack(spacing: 10) {
                    Text("\(vm.poppedIDs.count)/3")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.70))

                    ProgressView(value: Double(vm.poppedIDs.count), total: 3)
                        .tint(.white.opacity(0.75))
                        .frame(width: 120)
                }
                .padding(.bottom, 22)
                .opacity(vm.uiTextOpacity)
                
            }
            
            
        }
        .task { await vm.start() }
        .onDisappear { vm.stop() }
        .onAppear{
            vm.completeStep = {
                self.completeStep()
            }
        }
    }
}

@Observable
@MainActor
final class GestureSetupOnboardingVM {
 
     var cursorNormalized: CGPoint? = nil
     var isPinched: Bool = false
     var clicks: Int = 0

  
     var cameraOpacity: Double = 0.0
     var cameraBlur: CGFloat = 16
     var uiTextOpacity: Double = 0.0

  
     var balloons: [Balloon] = []
     var poppedIDs: Set<UUID> = []

   
     var primaryLine: String = "Move your fingers to aim."
     var secondaryLine: String = "Pinch to interact (Tap,Pop,etc)"

    @ObservationIgnored  private var sceneSize: CGSize = .zero

    @ObservationIgnored private let tracker = HandMovementTracker()

    var session: AVCaptureSession { tracker.captureSession }

    @ObservationIgnored private var started = false
    @ObservationIgnored private var lastPopTime: CFTimeInterval = 0

    @ObservationIgnored var completeStep:(()->Void)?
    func setSceneSize(_ size: CGSize) {
        sceneSize = size
    }

    func start() async {
        guard !started else { return }
        started = true

      
        balloons = [
            Balloon(seed: 1),
            Balloon(seed: 2),
            Balloon(seed: 3)
        ]
        poppedIDs.removeAll()

       
        tracker.onCursor = { [weak self] p in
            self?.cursorNormalized = p
        }
        tracker.onPinchChanged = { [weak self] pinched in
            self?.isPinched = pinched
        }
        tracker.onClick = { [weak self] in
            self?.clicks += 1
        }
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.tracker.updateConnectionOrientation()
        }

        tracker.start()

       
        withAnimation(.easeInOut(duration: 0.9)) {
            cameraOpacity = 1.0
            cameraBlur = 10
        }
        try? await Task.sleep(nanoseconds: 450_000_000)

        withAnimation(.easeInOut(duration: 0.6)) {
            uiTextOpacity = 1.0
        }

      
        try? await Task.sleep(nanoseconds: 900_000_000)
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraBlur = 4
        }

       
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 20_000_000_000)
            await MainActor.run { self?.completeIfNeeded() }
        }
    }

    func stop() {
        tracker.stop()
    }

   

    func balloonPosition(_ b: Balloon, in size: CGSize) -> CGPoint {
      
        let t = CACurrentMediaTime()
        let x = b.baseX * size.width + CGFloat(sin(t * b.speed + b.phase)) * b.driftX
        let y = b.baseY * size.height + CGFloat(cos(t * (b.speed * 0.9) + b.phase)) * b.driftY
        return CGPoint(x: x, y: y)
    }

    func isCursorInsideBalloon(_ b: Balloon, in size: CGSize) -> Bool {
        guard let c = cursorNormalized else { return false }
        let p = CGPoint(x: c.x * size.width, y: c.y * size.height)
        let center = balloonPosition(b, in: size)
        let r = b.radius
        return hypot(p.x - center.x, p.y - center.y) <= r
    }

    func tryPop(in size: CGSize) {
        guard poppedIDs.count < 3 else { return }
        guard let _ = cursorNormalized else { return }

       
        let now = CACurrentMediaTime()
        guard now - lastPopTime > 0.18 else { return }
        lastPopTime = now

       
        for b in balloons where !poppedIDs.contains(b.id) {
            if isCursorInsideBalloon(b, in: size) {
               _ = withAnimation(.easeInOut(duration: 0.18)) {
                    poppedIDs.insert(b.id)
                }
               
                if poppedIDs.count == 1 {
                    AudioManager.shared.playSFX(.click)
                    withAnimation(.easeInOut(duration: 0.35)) {
                        secondaryLine = "Pinch = tap."
                    }
                }
                if poppedIDs.count == 2 {
                    AudioManager.shared.playSFX(.click)
                    withAnimation(.easeInOut(duration: 0.35)) {
                        secondaryLine = "Move + pinch to select."
                    }
                }
                if poppedIDs.count == 3 {
                    AudioManager.shared.playSFX(.confirm)
                    complete()
                }
                break
            }
        }
    }

    private func complete() {
      
        withAnimation(.easeInOut(duration: 0.45)) {
            uiTextOpacity = 0.0
            cameraBlur = 2
        }
       
        completeStep?()
      
    }

    private func completeIfNeeded() {
        if poppedIDs.count < 3 {
          
            complete()
        }
    }
}



struct Balloon: Identifiable {
    let id = UUID()

  
    let baseX: CGFloat
    let baseY: CGFloat

   
    let driftX: CGFloat
    let driftY: CGFloat
    let speed: Double
    let phase: Double

    let radius: CGFloat

    init(seed: Int) {
      
        switch seed {
        case 1:
            baseX = 0.30; baseY = 0.38
            driftX = 18; driftY = 14
            speed = 0.55; phase = 0.3
            radius = 42
        case 2:
            baseX = 0.65; baseY = 0.46
            driftX = 22; driftY = 16
            speed = 0.50; phase = 1.1
            radius = 46
        default:
            baseX = 0.48; baseY = 0.67
            driftX = 16; driftY = 20
            speed = 0.58; phase = 2.0
            radius = 44
        }
    }
}

private struct BalloonView: View {
    let balloon: Balloon
    let isHovering: Bool
    let isPopped: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(isHovering ? 0.22 : 0.14))
                .overlay(
                    Circle().stroke(Color.white.opacity(isHovering ? 0.45 : 0.22), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)

          
            Circle()
                .fill(Color.white.opacity(0.20))
                .frame(width: 10, height: 10)
                .offset(x: -12, y: -14)
        }
        .frame(width: balloon.radius * 2, height: balloon.radius * 2)
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .opacity(isPopped ? 0 : 1)
        .animation(.easeInOut(duration: 0.12), value: isHovering)
    }
}
