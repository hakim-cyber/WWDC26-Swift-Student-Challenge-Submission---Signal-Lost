//
//  IMacPowerOnScene.swift
//  SignalLost
//
//  Created by aplle on 1/20/26.
//


import SwiftUI
import AVFoundation


struct IMacPowerOnScene: View {
    var onPowered: () -> Void
    @State private var vm = IMacPowerOnVM()

    var body: some View {
        GeometryReader { geo in
            let sceneSize = geo.size

            ZStack {
              EmergencyDeskBackground(viewSize: sceneSize)
                    .ignoresSafeArea()
                
              
             
                    ImacBackPowerView(isOn: $vm.buttonPressed)
                        .scaleEffect(1.05)
                        .opacity(vm.powered ? 0.92 : 1.0)
                    

           
                if vm.powerButtonFrame != .zero {
                   
                    if !vm.powered {
                        TargetHalo()
                            .frame(width: 90, height: 90)
                            .position(x: vm.powerButtonFrame.midX, y: vm.powerButtonFrame.midY)
                            .opacity(vm.showHint ? 1 : 0)
                            .transition(.opacity)
                    }

                  
                    if !vm.powered {
                        HintChip(text: "Pinch-tap the power button")
                            .position(x: vm.powerButtonFrame.midX - 110,
                                      y: vm.powerButtonFrame.midY - 80)
                            .opacity(vm.showHint ? 1 : 0)
                            .transition(.opacity)
                    }

                   
                    if vm.powered {
                        SuccessPulse()
                            .frame(width: 130, height: 130)
                            .position(x: vm.powerButtonFrame.midX, y: vm.powerButtonFrame.midY)
                            .transition(.opacity)
                    }
                }

              
                if let c = vm.cursorNormalized{
                                   CursorDot(isActive: vm.isPinched)
                                       .position(x: c.x * sceneSize.width,
                                                 y: c.y * sceneSize.height)
                               }
               
                VStack(spacing: 10) {
                    Spacer()

                    Text(vm.primaryText)
                        .font(.system(size: 22, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)

                    Text(vm.secondaryText)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.60))
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: 28)
                }
                .padding(.horizontal, 24)
                
                if !vm.handVisible {
                    HandMissingOverlay()
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
           
            .coordinateSpace(name: "macScene")

          

            .onAppear {
                vm.updateSceneSize(sceneSize)
                vm.start()
            }
            .onChange(of: sceneSize) { _, new in
                vm.updateSceneSize(new)
            }
            .onDisappear { vm.stop() }

            .onChange(of: vm.powered) { _, new in
                if new {
                    AudioManager.shared.playSFX(.imacPowerSFX)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        onPowered()
                    }
                }
            }
        }
        .environment(vm)
    }
}
 
private struct TargetHalo: View {
    @State private var pulse = false
    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.14), lineWidth: 2).blur(radius: 6)
            Circle().stroke(.white.opacity(0.12), lineWidth: 10).blur(radius: 18)
        }
        .scaleEffect(pulse ? 1.08 : 0.92)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
        .allowsHitTesting(false)
    }
}


private struct SuccessPulse: View {
    @State private var pop = false
    var body: some View {
        Circle()
            .stroke(.white.opacity(0.55), lineWidth: 18)
            .blur(radius: 18)
            .scaleEffect(pop ? 1.0 : 0.6)
            .opacity(pop ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.35)) { pop = true }
            }
            .allowsHitTesting(false)
    }
}

private struct HintChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundStyle(.black.opacity(0.92))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule(style: .continuous).fill(.white.opacity(0.92)))
            .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 0)
            .allowsHitTesting(false)
    }
}
@Observable
@MainActor
final class IMacPowerOnVM {
     var handVisible: Bool = false
 
     var cursorNormalized: CGPoint? = nil
     var isPinched: Bool = false
     var buttonPressed: Bool = false

    var powered: Bool = false
    var showHint: Bool = true
    var primaryText: String = "EMERGENCY POWER"
    var secondaryText: String = "Pinch-tap the power button."

   
    var powerButtonFrame: CGRect = .zero

  
    @ObservationIgnored   var sceneSize: CGSize = .zero

    @ObservationIgnored  private let tracker = HandMovementTracker()
    @ObservationIgnored  private var started = false

    @ObservationIgnored  private let hitPaddingPx: CGFloat = 18
    @ObservationIgnored  private var lastFailTime: CFTimeInterval = 0
    @ObservationIgnored  private let failCooldown: CFTimeInterval = 0.25

    func start() {
        guard !started else { return }
        started = true

        tracker.onCursor = { [weak self] p in
            self?.cursorNormalized = p
            self?.handVisible = (p != nil)
        }

        tracker.onPinchChanged = { [weak self] pinched in
            self?.isPinched = pinched
        }

        tracker.onClick = { [weak self] in
            self?.tryPowerTap()
        }

        tracker.start()
    }
    func updateSceneSize(_ s: CGSize) {
          sceneSize = s
      }


    func stop() { tracker.stop() }

    private func cursorPx(in size: CGSize) -> CGPoint? {
        guard let c = cursorNormalized, size.width > 0, size.height > 0 else { return nil }
        return CGPoint(x: c.x * size.width, y: c.y * size.height)
    }

    private func tryPowerTap() {
        guard handVisible else { return }
        guard !powered else { return }

        guard powerButtonFrame != .zero else {
            secondaryText = "Initializing target…"
            return
        }

        guard let cursorPx = cursorPx(in: sceneSize) else {
            showHint = true
            secondaryText = "Place your hand in frame."
            return
        }

        let padded = powerButtonFrame.insetBy(dx: -hitPaddingPx, dy: -hitPaddingPx)

        if padded.contains(cursorPx) {
            self.buttonPressed.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.buttonPressed.toggle() }
            powered = true
            showHint = false
            primaryText = "POWER ON"
            secondaryText = "Booting emergency interface…"
        } else {
            let now = CACurrentMediaTime()
            guard now - lastFailTime >= failCooldown else { return }
            lastFailTime = now

            showHint = true
            secondaryText = "Aim at the glowing circle."
        }
    }
}
