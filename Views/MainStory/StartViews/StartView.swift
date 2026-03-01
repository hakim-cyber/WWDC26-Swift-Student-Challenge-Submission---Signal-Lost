//
//  File.swift
//  Swift-Student-Challenge-2026-Distinguished
//
//  Created by aplle on 1/14/26.
//

import SwiftUI



struct StartView: View {
    @Environment(ProjectData.self) var data

    @State private var showTouchWarning = false
    @State private var touchWarningTask: Task<Void, Never>?

    var body: some View {
        ZStack {
          
            ZStack {
                switch data.startSteps {
                case .cameraAcces:
                    BootScreenView {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            data.changeStartStep(.showHandView)
                        }
                    }

                case .showHandView:
                    ShowHandView {
                        withAnimation(.easeInOut(duration: 0.55)) {
                            data.changeStartStep(.calibrationGuide)
                        }
                    }

                case .calibrationGuide:
                    CalibrationGuideView {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            data.changeStartStep(.gestureSetup1)
                        }
                    }

                case .gestureSetup1:
                    GestureSetupOnboardingView {
                        withAnimation(.easeInOut(duration: 0.55)) {
                            data.changeStartStep(.gestureSetup2)
                        }
                    }

                case .gestureSetup2:
                    ConnectionOnboardingView {
                        withAnimation(.easeInOut(duration: 0.55)) {
                            data.changeStartStep(.gestureSetup3)
                        }
                    }

                case .gestureSetup3:
                    DialOnboardingView {
                        withAnimation(.easeInOut(duration: 0.55)) {
                            data.changeStartStep(.gestureSetup4)
                        }
                    }

                case .gestureSetup4:
                    EyeMorseOnboardingView {
                        withAnimation(.easeInOut(duration: 0.55)) {
                            data.changeStartStep(.transitionToMain)
                        }
                    }

                case .transitionToMain:
                    TransitionToEmergencyTextView {
                        withAnimation(.easeInOut(duration: 0.55)) {
                            data.changeStartStep(.connectMacCable)
                        }
                    }
                    .sceneBGM(.mainStoryBackground, fade: 0.5)

                case .connectMacCable:
                    IMacPowerCableScene {
                        withAnimation(.easeInOut(duration: 0.55)) {
                            data.changeStartStep(.powerOnMac)
                        }
                    }

                case .powerOnMac:
                    IMacPowerOnScene {
                        withAnimation(.easeInOut(duration: 0.55)) {
                            data.changeStartStep(.bootProcessMac)
                        }
                    }

                case .bootProcessMac:
                    IMacBootSequenceTransitionView {
                        withAnimation(.easeInOut(duration: 0.75)) {
                            data.changeStartStep(.deskScene)
                        }
                    }

                case .deskScene:
                    DesktopScene()

                case .finishingScene:
                    SignalLostFinalMessageView { }
                        .sceneBGM(.finishBackground, fade: 0.5)
                    
                }
                
            }
            .requireIPadLandscape(minAspectRatio: 1.08)
            
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    guard data.startSteps != .cameraAcces else { return }
                    triggerTouchWarning()
                }
            )

           
            TouchInputWarningOverlay(visible: showTouchWarning)
                .allowsHitTesting(false)
        }
    }

   
    @MainActor
    private func triggerTouchWarning() {
        touchWarningTask?.cancel()

        withAnimation(.easeInOut(duration: 0.18)) {
            showTouchWarning = true
        }

      
        touchWarningTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_150_000_000) 
            withAnimation(.easeInOut(duration: 0.35)) {
                showTouchWarning = false
            }
        }
    }
}
