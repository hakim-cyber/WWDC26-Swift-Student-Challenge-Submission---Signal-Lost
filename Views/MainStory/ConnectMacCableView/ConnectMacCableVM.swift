
import SwiftUI
import AVFoundation
import Vision
import CoreGraphics

@Observable
@MainActor
final class ConnectMacCableVM {

   
    var cursorNormalized: CGPoint? = nil
   var isPinched: Bool = false
     var clicks: Int = 0

   
   var isGrabbed: Bool = false
   var isNear: Bool = false
   var isConnected: Bool = false
    var isHoveringMovable: Bool = false
    var showHandAlert: Bool = false

    @ObservationIgnored  private var size: CGSize = .zero

   
   var movableEnd = CableEnd(norm: CGPoint(x: 0.6, y: 0.70))
   var targetEnd  = CableEnd(norm: CGPoint(x: 0.78, y: 0.42))

    @ObservationIgnored private var grabOffsetNorm: CGPoint = .zero

    @ObservationIgnored private let connectDistancePx: CGFloat = 52
    @ObservationIgnored private let snapDistancePx: CGFloat = 26
    @ObservationIgnored private let grabRadiusPx: CGFloat = 84

    @ObservationIgnored private let tracker = HandMovementTracker()
    @ObservationIgnored private var started = false
    @ObservationIgnored private var lastClickTime: CFTimeInterval = 0

  
    @ObservationIgnored private var lastHandSeen: CFTimeInterval = 0
    @ObservationIgnored private let handMissingAfter: CFTimeInterval = 0.45

    @ObservationIgnored var onConnect: (() -> Void)?

    func setSceneSize(_ s: CGSize) { size = s }

    func start() async {
        guard !started else { return }
        started = true

      
        tracker.onCursor = { [weak self] p in
            guard let self else { return }
            self.cursorNormalized = p

            let now = CACurrentMediaTime()
            if p == nil {
              
                if (now - self.lastHandSeen) > self.handMissingAfter {
                    self.showHandAlert = true
                    if !self.isConnected { self.isGrabbed = false }
                }
            } else {
                self.lastHandSeen = now
                self.showHandAlert = false
            }
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

       
    }

    func stop() { tracker.stop() }

    func handleClick(in geo: CGSize) {
        guard throttleClick() else { return }
        guard !isConnected else { return }
        guard let cursor = cursorNormalized else { return }
        AudioManager.shared.playSFX(.click)
        let cursorPx = CGPoint(x: cursor.x * geo.width, y: cursor.y * geo.height)
        let movablePx = movableEnd.pos(in: geo)

        if !isGrabbed {
           
          
            let d = hypot(cursorPx.x - movablePx.x, cursorPx.y - movablePx.y)
            guard d < grabRadiusPx else { return }
            isGrabbed = true
            grabOffsetNorm = CGPoint(
                x: movableEnd.norm.x - cursor.x,
                y: movableEnd.norm.y - cursor.y
            )
        } else {
            
           
            isGrabbed = false
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
            new.x = min(max(new.x, 0.10), 0.90)
            new.y = min(max(new.y, 0.18), 0.88)
            movableEnd.norm = new
        }

        isNear = isWithinConnectDistance(in: geo)

        
        if isNear && isGrabbed {
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
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
        if showHandAlert { return "> no hand detected" }
        if isConnected { return "> link established" }
        if isGrabbed { return "> holding plug" }
        if isNear { return "> release to connect" }
        if isHoveringMovable { return "> pinch to grab" }
        return "> find the loose end"
    }

}




extension ConnectMacCableVM {
    func setFixedTarget(_ outletPx: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        targetEnd.norm = CGPoint(x: outletPx.x / size.width,
                                 y: outletPx.y / size.height)
    }
}
