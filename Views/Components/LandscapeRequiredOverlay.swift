//
//  LandscapeRequiredOverlay.swift
//  SignalLost
//
//  Created by aplle on 2/17/26.
//

import SwiftUI
 struct LandscapeRequiredOverlay: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.70).ignoresSafeArea()

            VStack(spacing: 14) {
                Text("ROTATE TO LANDSCAPE")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(.green.opacity(0.95))

                Text("This simulator is designed for iPad landscape.")
                    .font(.system(size: 12.5, weight: .regular, design: .monospaced))
                    .foregroundStyle(.green.opacity(0.70))
                    .multilineTextAlignment(.center)

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.green.opacity(0.20), lineWidth: 2)
                        .frame(width: 140, height: 88)

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.green.opacity(0.45), lineWidth: 2)
                        .frame(width: 140, height: 88)
                        .scaleEffect(pulse ? 1.06 : 0.96)
                        .opacity(pulse ? 0.0 : 1.0)
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 1.1).repeatForever(autoreverses: false)) {
                        pulse = true
                    }
                }

                Text("> waiting: landscape orientation")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(.green.opacity(0.55))
            }
            .padding(18)
            .frame(width: 360)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.black.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.green.opacity(0.30), lineWidth: 1)
                    )
            )
        }
        .allowsHitTesting(true)
    }
}

struct RequireLandscape: ViewModifier {
    let minAspectRatio: CGFloat
    let onlyIPad: Bool

    func body(content: Content) -> some View {
        GeometryReader { g in
            let size = g.size
            let aspect = size.width / max(1, size.height)
            let isLandscapeEnough = aspect >= minAspectRatio

            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            let shouldEnforce = onlyIPad ? isPad : true

            ZStack {
                content

                if shouldEnforce && !isLandscapeEnough {
                    LandscapeRequiredOverlay()
                        .ignoresSafeArea()
                        .allowsHitTesting(true)
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isLandscapeEnough)
        }
    }
}

extension View {
    
    func requireIPadLandscape(
       
        minAspectRatio: CGFloat = 1.05
    ) -> some View {
        modifier(RequireLandscape(minAspectRatio: minAspectRatio, onlyIPad: false))
    }
}
