//
//  BreakingNewsFinishView.swift
//  SignalLost
//
//  Created by aplle on 1/29/26.
//


import SwiftUI
import AVFoundation


struct BreakingNewsFinishView: View {
    var onDone: () -> Void

  
    var headline: String = "RESCUE CONFIRMED"
    var subhead: String =
"""
Authorities confirm that an individual was rescued today after transmitting a manual SOS using optical hand and eye controls.
Standard touch input was unavailable, requiring gesture-based systems to restore power, tune a signal relay, and send Morse code.
The signal was received, verified, and emergency responders were dispatched immediately.
The individual was recovered safely.
"""
  
   
    @State private var livePulse = false
    @State private var breakingFlash = false
   
    @State private var showVerified = false
    @State private var dispatchPulse = false
    @State private var uiOpacity: Double = 0
    @State private var vignetteStrength: Double = 0.0

  
    var autoDismiss: Bool = true
    var dismissAfter: Double = 15.0

    var body: some View {
        GeometryReader { g in
            let size = g.size

            ZStack {
               
                Image("breaking_news_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .ignoresSafeArea()

          
              
                VStack(spacing: 0) {
                  
                    topBreakingBar
                        .padding(.top, 14)
                        .padding(.horizontal, 16)

                    Spacer()

                   
                    if showVerified {
                        verifiedBadge
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            .padding(.bottom, 18)
                    }

                    
                    lowerThird
                        .padding(.horizontal, 18)
                        .padding(.bottom, 16)

                }
                .opacity(uiOpacity)
            }
            .onAppear {
                animateIn()
                scheduleMoments()

                if autoDismiss {
                    DispatchQueue.main.asyncAfter(deadline: .now() + dismissAfter) {
                        animateOutAndDone()
                    }
                }
            }
        }
        .sceneBGM(.newsBackground, fade: 0.5)
    }

    

    private var topBreakingBar: some View {
        HStack(spacing: 10) {
          
            HStack(spacing: 8) {
                Circle()
                    .fill(.red.opacity(livePulse ? 1.0 : 0.55))
                    .frame(width: 8, height: 8)
                    .shadow(color: .red.opacity(0.55), radius: livePulse ? 10 : 4)

                Text("LIVE")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.black.opacity(0.40))
                    .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
            )

            HStack(spacing: 10) {
                Text("BREAKING")
                    .font(.system(size: 14, weight: .black, design: .default))
                    .foregroundStyle(.white)

                Text("NEWS")
                    .font(.system(size: 14, weight: .black, design: .default))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.red.opacity(breakingFlash ? 0.92 : 0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.white.opacity(0.22), lineWidth: 1)
                    )
            )
            .shadow(color: .red.opacity(0.35), radius: breakingFlash ? 18 : 10, x: 0, y: 6)

            Spacer()

            
            VStack(alignment: .trailing, spacing: 4) {
                Text(Date.now.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.70))

                Text("EMERGENCY NETWORK")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true)) {
                livePulse.toggle()
            }
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                breakingFlash.toggle()
            }
        }
    }

   

    private var verifiedBadge: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.22))
                    .frame(width: 54, height: 54)
                    .overlay(Circle().stroke(.green.opacity(0.35), lineWidth: 1))

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.green.opacity(0.92))
            }
            .overlay(
                Circle()
                    .stroke(.green.opacity(dispatchPulse ? 0.30 : 0.0), lineWidth: 18)
                    .blur(radius: 16)
                    .scaleEffect(dispatchPulse ? 1.22 : 0.92)
                    .opacity(dispatchPulse ? 1 : 0)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("SIGNAL VERIFIED")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.92))

                Text("Responders dispatched immediately")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.70))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.black.opacity(0.38))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        )
        .frame(maxWidth: 720)
        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 12)
    }

  

    private var lowerThird: some View {
        VStack(alignment: .leading, spacing: 12) {
         
            HStack(alignment: .center) {
                Text(headline)
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(.white.opacity(0.95))

                Spacer()

                Text("CONFIRMED")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.10))
                            .overlay(Capsule().stroke(.white.opacity(0.16), lineWidth: 1))
                    )
            }

          
            Text(subhead)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.80))
                .lineSpacing(3)

            
            HStack(spacing: 10) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.70))

                Text("OPTICAL SOS RECEIVED • MORSE VERIFIED • DISPATCH ACTIVE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.62))

                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        )
        .frame(maxWidth: 920)
        .shadow(color: .black.opacity(0.35), radius: 22, x: 0, y: 16)
    }

   
    

    private func animateIn() {
        uiOpacity = 0
        vignetteStrength = 0
        withAnimation(.easeInOut(duration: 0.45)) { uiOpacity = 1 }
        withAnimation(.easeInOut(duration: 0.75)) { vignetteStrength = 1.0 }
    }

    private func scheduleMoments() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeInOut(duration: 0.35)) { showVerified = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.55)) { dispatchPulse = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.35)) { dispatchPulse = false }
        }
    }

    private func animateOutAndDone() {
        withAnimation(.easeInOut(duration: 0.55)) {
            uiOpacity = 0
            vignetteStrength = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) {
            onDone()
        }
    }
}
