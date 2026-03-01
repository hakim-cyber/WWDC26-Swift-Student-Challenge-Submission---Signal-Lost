import SwiftUI


struct ViewFrameKey: PreferenceKey {
       static let defaultValue: CGRect = .zero
     static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

extension View {
    func reportFrame(in space: CoordinateSpace) -> some View {
        background(
            GeometryReader { g in
                Color.clear
                    .preference(key: ViewFrameKey.self,
                                value: g.frame(in: space))
            }
        )
    }
}

enum SceneAnchor: Hashable {
    case imac
    case cableSocket
}

 struct AnchorFramesKey:   PreferenceKey {
    static let defaultValue: [SceneAnchor: CGRect] = [:]
    static func reduce(value: inout [SceneAnchor: CGRect], nextValue: () -> [SceneAnchor: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    func reportFrame(_ id: SceneAnchor, in space: CoordinateSpace) -> some View {
        background(
            GeometryReader { g in
                Color.clear.preference(
                    key: AnchorFramesKey.self,
                    value: [id: g.frame(in: space)]
                )
            }
        )
    }
}
