//
//  HandMissingOverlay.swift
//  SignalLost
//
//  Created by aplle on 1/23/26.
//

import SwiftUI


struct HandMissingOverlay: View {
    @State private var pulse = false

    var body: some View {
        GeometryReader { g in
            let size = g.size
            let minSide = min(size.width, size.height)

         
            let cardW = min(size.width * 0.48, 520)
            let cardPad = max(18, minSide * 0.035)

           
            let titleSize = max(16, min(24, cardW * 0.045))
            let bodySize  = max(12, min(16, cardW * 0.030))

       
            let ringSize = max(96, min(160, minSide * 0.18))
            let ringLineThin = max(1.5, ringSize * 0.012)
            let ringLineThick = max(3.5, ringSize * 0.040)

            ZStack {
                Color.black.opacity(0.75)
                    .ignoresSafeArea()

                VStack(spacing: max(10, minSide * 0.02)) {
                    Text("NO HAND DETECTED")
                        .font(.system(size: titleSize, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.95))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("Place one hand fully inside the camera view.")
                        .font(.system(size: bodySize, weight: .regular))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: cardW * 0.82)

                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.10), lineWidth: ringLineThin)
                            .frame(width: ringSize, height: ringSize)

                        Circle()
                            .stroke(.white.opacity(0.25), lineWidth: ringLineThick)
                            .frame(width: ringSize, height: ringSize)
                            .scaleEffect(pulse ? 1.12 : 0.92)
                            .opacity(pulse ? 0.0 : 1.0)
                    }
                    .onAppear {
                        pulse = false
                        withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                            pulse = true
                        }
                    }
                }
                .padding(cardPad)
                .frame(width: cardW)
                .background(
                    RoundedRectangle(cornerRadius: max(16, minSide * 0.03), style: .continuous)
                        .fill(.black.opacity(0.55))
                        .overlay(
                            RoundedRectangle(cornerRadius: max(16, minSide * 0.03), style: .continuous)
                                .stroke(.white.opacity(0.12), lineWidth: max(1, minSide * 0.0018))
                        )
                )
                .position(x: size.width * 0.5, y: size.height * 0.5)
            }
        }
        .allowsHitTesting(true)
    }
}
