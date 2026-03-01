//
//  StableSignalRelayTip.swift
//  SignalLost
//
//  Created by aplle on 1/25/26.
//


import SwiftUI

struct StableSignalRelayTip: View {
    let relayFrame: CGRect
    @State private var pulse = false

    var body: some View {
        ZStack {
          
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(pulse ? 0.28 : 0.14), lineWidth: 2)
                .frame(width: relayFrame.width + 18, height: relayFrame.height + 18)
                .position(x: relayFrame.midX, y: relayFrame.midY)
                .blur(radius: pulse ? 2 : 1)
                .shadow(color: .blue.opacity(pulse ? 0.35 : 0.15), radius: 18)
                .allowsHitTesting(false)

          
            tooltip
                .position(
                    x: relayFrame.midX,
                    y: relayFrame.minY - 70
                )
                .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse.toggle()
            }
        }
    }

    private var tooltip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))

                Text("Open Signal Relay")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
            }

            Text("This is the only active channel.")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))

            Text("Use it to request help and restore communication.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.white.opacity(0.70))

            Text("Pinch to click.")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.65))
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 310, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 18)
    }
}
