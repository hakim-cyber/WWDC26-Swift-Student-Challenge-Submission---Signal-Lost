//
//  SignalLostFinalMessageView.swift
//  SignalLost
//
//  Created by aplle on 1/30/26.
//

import SwiftUI

struct SignalLostFinalMessageView: View {
  
    var autoFinish: Bool = false
    var onFinished: (() -> Void)? = nil

    @State private var stage: Int = 0
    
    @State private var fade: Double = 0
    @State private var scale: CGFloat = 0.985
    @State private var blur: CGFloat = 12

    
    @State private var line4Opacity: Double = 0
    @State private var line4Offset: CGFloat = 14
    @State private var line4Blur: CGFloat = 10

   
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 18
    @State private var titleBlur: CGFloat = 12

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            RadialGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.black.opacity(0.88)
                ]),
                center: .center,
                startRadius: 160,
                endRadius: 980
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                messageBlock

                if stage >= 5 {
                    appTitleBlock
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()
            }
            .padding(.horizontal, 28)
            .opacity(fade)
            .scaleEffect(scale)
            .blur(radius: blur)
        }
        .onAppear { runReadableSequence() }
        .accessibilityElement(children: .contain)
    }

   

    private var messageBlock: some View {
        VStack(spacing: 18) {
            line("Touch input was unavailable.", index: 1, weight: .regular, opacity: 0.92)
            line("The system activated emergency optical controls.", index: 2, weight: .regular, opacity: 0.92)
            line("You restored communication using your hands and eyes.", index: 3, weight: .semibold, opacity: 0.96)

            Text("When traditional input fails, the system adapts.")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.80))
                .padding(.top, 8)
                .opacity(stage >= 4 ? line4Opacity : 0)
                .offset(y: stage >= 4 ? line4Offset : 14)
                .blur(radius: stage >= 4 ? line4Blur : 10)
                .animation(.easeOut(duration: 0.65), value: line4Opacity)
                .animation(.easeOut(duration: 0.65), value: line4Offset)
                .animation(.easeOut(duration: 0.65), value: line4Blur)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 38)
        .accessibilityLabel(accessibilitySummary)
    }

    private func line(_ text: String, index: Int, weight: Font.Weight, opacity: Double) -> some View {
        Text(text)
            .font(.system(size: 20, weight: weight))
            .foregroundStyle(.white.opacity(opacity))
            .opacity(stage >= index ? 1 : 0)
            .offset(y: stage >= index ? 0 : 14)
            .blur(radius: stage >= index ? 0 : 8)
            .animation(.easeOut(duration: 0.55), value: stage)
    }

    private var appTitleBlock: some View {
        VStack(spacing: 10) {
            Text("Signal Lost")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.96))

            Text("An interactive experience using hand and eye tracking\nto demonstrate adaptive emergency interaction.")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
        )
        .opacity(titleOpacity)
        .offset(y: titleOffset)
        .blur(radius: titleBlur)
        .onAppear {
            withAnimation(.easeOut(duration: 0.70)) {
                titleOpacity = 1
                titleOffset = 0
                titleBlur = 0
            }
        }
    }

    private var accessibilitySummary: String {
        "Touch input was unavailable. The system activated emergency optical controls. You restored communication using your hands and eyes. When traditional input fails, the system adapts."
    }

   

    private func runReadableSequence() {
       
        stage = 0
        line4Opacity = 0
        line4Offset = 14
        line4Blur = 10
        titleOpacity = 0
        titleOffset = 18
        titleBlur = 12

     
        fade = 0
        scale = 0.985
        blur = 12

        withAnimation(.easeOut(duration: 0.85)) {
            fade = 1
            scale = 1.0
            blur = 0
        }

      
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.90) { stage = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.10) { stage = 2 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.30) { stage = 3 }

     
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.90) {
            stage = 4
            withAnimation(.easeOut(duration: 0.75)) {
                line4Opacity = 1
                line4Offset = 0
                line4Blur = 0
            }
        }

      
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            stage = 5
        }

    
        if autoFinish {
            DispatchQueue.main.asyncAfter(deadline: .now() + 16.0) {
                onFinished?()
            }
        }
    }
}

#Preview {
    SignalLostFinalMessageView(autoFinish: false)
}
