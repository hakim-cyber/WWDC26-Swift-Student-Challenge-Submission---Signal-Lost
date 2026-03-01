

import SwiftUI


struct CursorPressStyle: ButtonStyle {
    var isHovered: Bool
    var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity((configuration.isPressed || isPressed) ? 0.6 : isHovered ? 1.0 : 0.9)
            .scaleEffect((configuration.isPressed || isPressed) ? 0.98 : isHovered ? 1.05 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .animation(.easeOut(duration: 0.12), value: isPressed)
    }
}

struct CursorTrackableButton<Label: View>: View {
    let cursorNormalized: CGPoint?
    let isPinched: Bool
    let geoSize: CGSize
    let action: () -> Void

  
    var onHoverChanged: ((Bool) -> Void)? = nil

    @ViewBuilder var label: (_ isHovering: Bool) -> Label

    @State private var frame: CGRect = .zero
    @State private var isHovering: Bool = false
    @State private var isTapped: Bool = false
    @State private var lastClickTime: CFTimeInterval = 0

    
    var body: some View {
        Button(action: action) {
            label(isHovering)
        }
        .buttonStyle(CursorPressStyle(isHovered: isHovering, isPressed: isTapped))
        .reportFrame(in: .named("root"))
        .onPreferenceChange(ViewFrameKey.self) { rect in
            frame = rect
                if rect == .zero { setHover(false) }
                else { updateHover() }
        }

      
        .onChange(of: cursorNormalized) {
            updateHover()
        }

       
        .onChange(of: isPinched) { oldValue,newValue in
            guard frame != .zero else { return }
            if newValue == true && oldValue == false {
                if isHovering && canClickNow() { tap() }
            }
            
        }
    }
    private func canClickNow() -> Bool {
        let now = CACurrentMediaTime()
        if now - lastClickTime < 0.20 { return false }
        lastClickTime = now
        return true
    }
    func tap() {
        action()
        isTapped = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            isTapped = false
        }
    }
    private func updateHover() {
        guard let c = cursorNormalized else {
            setHover(false)
            return
        }

        let point = CGPoint(x: c.x * geoSize.width, y: c.y * geoSize.height)
        setHover(frame.contains(point))
    }

    private func setHover(_ value: Bool) {
        guard value != isHovering else { return } 
        isHovering = value
        onHoverChanged?(value)
    }
}
