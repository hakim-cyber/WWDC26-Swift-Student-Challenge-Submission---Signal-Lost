import SwiftUI
import AVFoundation



struct ConnectionOnboardingView: View {
    @State private var vm = ConnectionOnboardingVM()

    var onComplete:()->()
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreviewView(session: vm.session)
                .ignoresSafeArea()
                .opacity(0.85)
                .blur(radius: 4)
                .overlay(Color.black.opacity(0.48))
                .allowsHitTesting(false)

            RadialGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.78)]),
                center: .center,
                startRadius: 120,
                endRadius: 900
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            HelpOverlayCard(
                headerIcon: "bolt.fill",
                headerIconColor: .yellow,
                title: "Connection Training",
                bodyText: """
                Pinch to grab the loose connector.
                Move it to the target end, then pinch again to connect.
                """,
                tips: [
                    .init(icon: "cursorarrow.rays", text: "Hover the loose end (left)."),
                    .init(icon:  "hand.pinch", text: "Pinch to grab / pinch again to release."),
                    .init(icon: "arrow.right.circle.fill", text: "Drag toward the right connector."),
                    .init(icon: "circle.dashed", text: "When the ring appears, release to connect.")
                ],
                footerLeft: vm.isConnected ? "> link established"
                         : vm.isGrabbed ? "> holding connector"
                         : vm.isNear ? "> release to connect"
                         : vm.isHoveringMovable ? "> pinch to grab"
                         : "> find the loose end",
                footerRight: "Gesture Mode",
                width: 360,
                showsClose: false
            )
            .padding(.top, 18)
            .padding(.trailing, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            GeometryReader { geo in
                ZStack {
                    let leftPx  = vm.movableEnd.pos(in: geo.size)
                    let rightPx = vm.targetEnd.pos(in: geo.size)

                    
                    CableCurve(
                        a: leftPx,
                        b: rightPx,
                        bulge: vm.isGrabbed ? 0.22 : 0.16,
                        isNear: vm.isNear,
                        isConnected: vm.isConnected
                    )

                   
                    CableConnectorHead(
                        style: .target,
                        isHover: vm.isNear,
                        isGrabbed: false,
                        isConnected: vm.isConnected
                    )
                    .position(rightPx)

                   
                    CableConnectorHead(
                        style: .movable,
                        isHover: vm.isHoveringMovable,
                        isGrabbed: vm.isGrabbed,
                        isConnected: vm.isConnected
                    )
                    .position(leftPx)

                   
                    if vm.isNear && !vm.isConnected {
                        MagneticRing()
                            .position(rightPx)
                            .transition(.opacity)
                    }

                   
                    if let c = vm.cursorNormalized {
                        CursorDot(isActive: vm.isGrabbed || vm.isPinched)
                            .position(x: c.x * geo.size.width, y: c.y * geo.size.height)
                         
                    }
                }
                .onAppear { vm.setSceneSize(geo.size) }
                .onChange(of: geo.size) { _, s in vm.setSceneSize(s) }
                .onChange(of: vm.clicks) { _, _ in vm.handleClick(in: geo.size) }
                .onChange(of: vm.cursorNormalized) { _, _ in vm.updateDragAndHover(in: geo.size) }
            }

            VStack {
                Text("CONNECTION")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.top, 18)
                    .opacity(vm.uiOpacity)

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
                .opacity(vm.uiOpacity)

                Spacer()

                Text(vm.footerText)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.bottom, 22)
                    .opacity(vm.uiOpacity)
            }
        }
        .task { await vm.start() }
        .onDisappear { vm.stop() }
        .onAppear{
            vm.onConnect = {
                self.onComplete()
            }
        }
    }
}


@Observable
@MainActor
final class ConnectionOnboardingVM {
     var cursorNormalized: CGPoint? = nil
     var isPinched: Bool = false
     var clicks: Int = 0

     var isGrabbed: Bool = false
     var isNear: Bool = false
     var isConnected: Bool = false
     var isHoveringMovable: Bool = false

     var uiOpacity: Double = 0.0
     var primaryText: String = "Pinch to grab the cable."
     var secondaryText: String = "Move it, then release."
   
    @ObservationIgnored private var size: CGSize = .zero

   
     var movableEnd = CableEnd(norm: CGPoint(x: 0.33, y: 0.50))
     var targetEnd  = CableEnd(norm: CGPoint(x: 0.68, y: 0.55))

    @ObservationIgnored private var grabOffsetNorm: CGPoint = .zero

    @ObservationIgnored  private let connectDistancePx: CGFloat = 42
    @ObservationIgnored private let snapDistancePx: CGFloat = 22
    @ObservationIgnored private let grabRadiusPx: CGFloat = 60

    @ObservationIgnored  private let tracker = HandMovementTracker()
    var session: AVCaptureSession { tracker.captureSession }

    @ObservationIgnored private var started = false
    @ObservationIgnored private var lastClickTime: CFTimeInterval = 0

    func setSceneSize(_ s: CGSize) { size = s }

    @ObservationIgnored var onConnect:(()->Void)?
    func start() async {
        guard !started else { return }
        started = true


        tracker.onCursor = { [weak self] p in self?.cursorNormalized = p }
        tracker.onPinchChanged = { [weak self] pinched in self?.isPinched = pinched }
        tracker.onClick = { [weak self] in self?.clicks += 1 }
        
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.tracker.updateConnectionOrientation()
        }
        
        tracker.start()

        withAnimation(.easeInOut(duration: 0.6)) { uiOpacity = 1.0 }

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 20_000_000_000)
            await MainActor.run { self?.finishIfNeeded() }
        }
    }

    func stop() { tracker.stop() }

    func handleClick(in geo: CGSize) {
        guard throttleClick() else { return }
        guard !isConnected else { return }
        guard let cursor = cursorNormalized else { return }

        let cursorPx = CGPoint(x: cursor.x * geo.width, y: cursor.y * geo.height)
        let movablePx = movableEnd.pos(in: geo)

      
        if !isGrabbed {
            AudioManager.shared.playSFX(.click)
            let d = hypot(cursorPx.x - movablePx.x, cursorPx.y - movablePx.y)
            guard d < grabRadiusPx else { return }

            isGrabbed = true
            primaryText = "Move to align."
            secondaryText = "Pinch again to connect."
            grabOffsetNorm = CGPoint(x: movableEnd.norm.x - cursor.x,
                                    y: movableEnd.norm.y - cursor.y)
        } else {
         
            isGrabbed = false
            primaryText = "Hold to move."
            secondaryText = "Bring the ends together."

            if isNear {
                AudioManager.shared.playSFX(.confirm)
                connect()
            }
        }
    }

    func updateDragAndHover(in geo: CGSize) {
        guard !isConnected else { return }

       
        isHoveringMovable = isCursorNearMovable(in: geo)

        if isGrabbed, let cursor = cursorNormalized {
            var new = CGPoint(x: cursor.x + grabOffsetNorm.x, y: cursor.y + grabOffsetNorm.y)
            new.x = min(max(new.x, 0.06), 0.94)
            new.y = min(max(new.y, 0.10), 0.90)
            movableEnd.norm = new
        }

        isNear = isWithinConnectDistance(in: geo)

       
        if isNear && isGrabbed == true {
            let d = distancePx(from: movableEnd.pos(in: geo), to: targetEnd.pos(in: geo))
            if d < snapDistancePx {
                movableEnd.norm = targetEnd.norm
            }
        }
    }

    private func isCursorNearMovable(in geo: CGSize) -> Bool {
        guard let c = cursorNormalized else { return false }
        let p = CGPoint(x: c.x * geo.width, y: c.y * geo.height)
        let m = movableEnd.pos(in: geo)
        return hypot(p.x - m.x, p.y - m.y) < grabRadiusPx
    }

    private func isWithinConnectDistance(in geo: CGSize) -> Bool {
        let d = distancePx(from: movableEnd.pos(in: geo), to: targetEnd.pos(in: geo))
        return d <= connectDistancePx
    }

    private func distancePx(from a: CGPoint, to b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    private func connect() {
        isConnected = true
        isNear = false
        isGrabbed = false
        movableEnd.norm = targetEnd.norm

        withAnimation(.easeInOut(duration: 0.25)) {
            primaryText = "Connected."
            secondaryText = "You can move and place UI elements."
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.45)) { self.uiOpacity = 0.0 }
          
            self.onConnect?()
        }
    }

    private func throttleClick() -> Bool {
        let now = CACurrentMediaTime()
        if now - lastClickTime < 0.22 { return false }
        lastClickTime = now
        return true
    }

    var footerText: String {
        if isConnected { return "> link established" }
        if isGrabbed { return "> holding connector" }
        if isNear { return "> release to connect" }
        if isHoveringMovable { return "> pinch to grab" }
        return "> find the loose end"
    }

    private func finishIfNeeded() {
        if !isConnected {
            withAnimation(.easeInOut(duration: 0.45)) { uiOpacity = 0.0 }
           
            onConnect?()
        }
    }
}



struct CableEnd: Identifiable {
    let id = UUID()
    var norm: CGPoint

    func pos(in size: CGSize) -> CGPoint {
        CGPoint(x: norm.x * size.width, y: norm.y * size.height)
    }
}



private struct CableCurve: View {
    let a: CGPoint
    let b: CGPoint
    let bulge: CGFloat
    let isNear: Bool
    let isConnected: Bool

    var body: some View {
        let path = cubicCablePath(from: a, to: b, bulge: bulge)

        return path
            .stroke(Color.white.opacity(isConnected ? 0.55 : (isNear ? 0.40 : 0.22)),
                    style: StrokeStyle(lineWidth: isConnected ? 8 : 6, lineCap: .round, lineJoin: .round))
            .overlay(
             
                path.stroke(Color.black.opacity(0.30),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .blendMode(.overlay)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 10)
            .animation(.easeInOut(duration: 0.18), value: isNear)
            .animation(.easeInOut(duration: 0.18), value: isConnected)
    }

    private func cubicCablePath(from a: CGPoint, to b: CGPoint, bulge: CGFloat) -> Path {
        var p = Path()
        p.move(to: a)

      
        let dx = b.x - a.x
        let dy = b.y - a.y
        let len = max(1, hypot(dx, dy))
        let nx = -dy / len
        let ny = dx / len

        let amount = min(140, max(60, len * 0.28)) * bulge

        let c1 = CGPoint(x: a.x + dx * 0.33 + nx * amount,
                         y: a.y + dy * 0.33 + ny * amount)

        let c2 = CGPoint(x: a.x + dx * 0.66 + nx * amount,
                         y: a.y + dy * 0.66 + ny * amount)

        p.addCurve(to: b, control1: c1, control2: c2)
        return p
    }
}

private struct CableConnectorHead: View {
    enum Style { case movable, target }

    let style: Style
    let isHover: Bool
    let isGrabbed: Bool
    let isConnected: Bool

    var body: some View {
        let base = Color.white.opacity(style == .movable ? 0.26 : 0.12)
        let stroke = Color.white.opacity(isConnected ? 0.55 : (isHover || isGrabbed ? 0.65 : 0.38))

        ZStack {
           
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(base)
                .frame(width: 70, height: 46)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(stroke, lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.30), radius: 16, x: 0, y: 10)

           
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 6, height: 16)
                }
            }
            .opacity(0.9)

           
            if isGrabbed {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 8)
                    .blur(radius: 12)
                    .frame(width: 82, height: 58)
            }
        }
        .scaleEffect(isGrabbed ? 1.07 : (isHover ? 1.03 : 1.0))
        .animation(.easeInOut(duration: 0.12), value: isHover)
        .animation(.easeInOut(duration: 0.12), value: isGrabbed)
        .allowsHitTesting(false)
    }
}

 struct CursorDot: View {
    let isActive: Bool
    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.92)).frame(width: 12, height: 12)
            Circle()
                .stroke(Color.white.opacity(isActive ? 0.95 : 0.35), lineWidth: 2)
                .frame(width: 22, height: 22)
                .opacity(isActive ? 1.0 : 0.6)
        }
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
        .animation(.easeInOut(duration: 0.10), value: isActive)
        .allowsHitTesting(false)
    }
}
