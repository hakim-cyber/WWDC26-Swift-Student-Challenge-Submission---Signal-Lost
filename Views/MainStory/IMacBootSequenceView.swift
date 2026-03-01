import SwiftUI

struct IMacBootSequenceTransitionView: View {
    var onFinished: () -> Void

   
    private let lineFade: Double = 0.40
    private let linePause: Double = 0.35
    private let afterTextHold: Double = 0.80

    private let glowIn: Double = 0.55
    private let glowHold: Double = 0.60

    private let revealDuration: Double = 0.95
    private let settleHold: Double = 0.75

    
    @State private var show1 = false
    @State private var show2 = false
    @State private var show3 = false
    @State private var show4 = false
    @State private var showGlow = false

    @State private var revealIMac = false
    @State private var startIMacBoot = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
               
                Color.black.ignoresSafeArea()

                bootTextLayer
                    .opacity(revealIMac ? 0.0 : 1.0)
                    .animation(.easeInOut(duration: 0.55), value: revealIMac)

               
                if revealIMac {
                    ZStack {
                        EmergencyDeskBackground(viewSize: size)
                            .ignoresSafeArea()

                        iMacView {
                          
                            if startIMacBoot {
                                AppleBootScreenView()
                            } else {
                                Color.black
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 1.04)))
                        .animation(.easeInOut(duration: revealDuration), value: revealIMac)
                    }
                }
            }
            .onAppear { runSequence() }
        }
    }

   
    private var bootTextLayer: some View {
        VStack(alignment: .leading, spacing: 10) {
            if show1 {
                Text("Starting system…")
                    .transition(.opacity)
            }
            if show2 {
                Text("Emergency mode enabled.")
                    .transition(.opacity)
            }
            if show3 {
                Text("Touch input unavailable.")
                    .transition(.opacity)
              
            }
            if show4 {
                Text("Hand controls active.")
                    .transition(.opacity)
            }

            
        }
        .font(.system(size: 16, weight: .regular, design: .monospaced))
        .foregroundStyle(.white.opacity(0.90))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .frame(width: 360, alignment: .leading)
        .offset(x: -12)
        .padding(.horizontal, 44)
    }

  
    private func runSequence() {
        Task { @MainActor in
          
            withAnimation(.easeInOut(duration: lineFade)) { show1 = true }

            
            try? await Task.sleep(nanoseconds: UInt64((lineFade + linePause) * 1_000_000_000))

           
         
            withAnimation(.easeInOut(duration: lineFade)) { show2 = true }

            try? await Task.sleep(nanoseconds: UInt64((lineFade + linePause) * 1_000_000_000))


            withAnimation(.easeInOut(duration: lineFade)) { show3 = true }

            try? await Task.sleep(nanoseconds: UInt64((lineFade + afterTextHold) * 1_000_000_000))
            withAnimation(.easeInOut(duration: lineFade)) { show4 = true }

            try? await Task.sleep(nanoseconds: UInt64((lineFade + afterTextHold) * 1_000_000_000))

           
            withAnimation(.easeInOut(duration: glowIn)) { showGlow = true }
            try? await Task.sleep(nanoseconds: UInt64((glowIn + glowHold) * 1_000_000_000))

           
            withAnimation(.easeInOut(duration: revealDuration)) {
                revealIMac = true
            }

         
            try? await Task.sleep(nanoseconds: UInt64(0.35 * 1_000_000_000))
            startIMacBoot = true

           
            try? await Task.sleep(nanoseconds: UInt64(settleHold * 1_000_000_000))
            onFinished()
            AudioManager.shared.stopSFX(.imacPowerSFX)
            
        }
    }
}

private struct AppleBootScreenView: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black

            VStack(spacing: 26) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 78, weight: .regular))
                    .foregroundStyle(.white)

                BootProgressBar(progress: progress)
                    .frame(width: 260, height: 6)
            }
        }
        .onAppear {
           
            progress = 0.02
            withAnimation(.easeInOut(duration: 3.2)) {
                progress = 1.0
            }
        }
    }
}

private struct BootProgressBar: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.18))
                Capsule()
                    .fill(.white.opacity(0.75))
                    .frame(width: max(6, w * min(max(progress, 0), 1)))
            }
        }
    }
}
