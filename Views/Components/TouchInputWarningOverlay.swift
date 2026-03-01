//
//  TouchInputWarningOverlay.swift
//  SignalLost
//
//  Created by aplle on 2/3/26.
//

import SwiftUI

 struct TouchInputWarningOverlay: View {
    let visible: Bool

    var body: some View {
        ZStack {
            
            Color.black
                .opacity(visible ? 0.72 : 0.0)
                .ignoresSafeArea()

           
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(visible ? 0.06 : 0.0))
                .blur(radius: visible ? 10 : 0)
                .ignoresSafeArea()

        
            VStack(spacing: 10) {
                Text("Touch is disabled")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))

                Text("Touch input isn’t available right now.\nUse hand and eye controls to continue.")
                    .font(.system(size: 13.5, weight: .regular))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.45), radius: 26, x: 0, y: 16)
            .opacity(visible ? 1 : 0)
            .scaleEffect(visible ? 1.0 : 0.98)
        }
        .animation(.easeInOut(duration: 0.25), value: visible)
    }
}
