import SwiftUI

extension View {
  
    func randomPosition(in size: CGSize, padding: CGFloat = 20, trigger: AnyHashable = 0) -> some View {
        modifier(RandomPositionModifier(size: size, padding: padding, trigger: trigger))
    }
}

private struct RandomPositionModifier: ViewModifier {
    let size: CGSize
    let padding: CGFloat
    let trigger: AnyHashable

    @State private var pos: CGPoint = .init(x: 100, y: 100)

    func body(content: Content) -> some View {
        content
            .position(pos)
            .onAppear { pos = makeRandomPoint() }
            .onChange(of: trigger) { pos = makeRandomPoint() }
            .onChange(of: size) { pos = makeRandomPoint() }
    }

    private func makeRandomPoint() -> CGPoint {
        let w = max(1, size.width)
        let h = max(1, size.height)

        let x = CGFloat.random(in: padding...(w - padding))
        let y = CGFloat.random(in: padding...(h - padding))
        return CGPoint(x: x, y: y)
    }
}
