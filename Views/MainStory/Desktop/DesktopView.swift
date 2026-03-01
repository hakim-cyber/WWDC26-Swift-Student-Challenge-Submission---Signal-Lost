//
//  DesktopView.swift
//  SignalLost
//
//  Created by aplle on 1/24/26.
//



import SwiftUI

enum DesktopTarget: Hashable { case signalRelay}


struct DesktopTargetFramesKey:   PreferenceKey {
     static let defaultValue: [DesktopTarget: CGRect] = [:]
     static func reduce(value: inout [DesktopTarget: CGRect], nextValue: () -> [DesktopTarget: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    func reportTargetFrame(_ target: DesktopTarget, in space: CoordinateSpace) -> some View {
        background(
            GeometryReader { g in
                Color.clear.preference(key: DesktopTargetFramesKey.self,
                                       value: [target: g.frame(in: space)])
            }
        )
    }
}



struct DesktopView: View {
    @Environment(ProjectData.self) var data
    let showHandAlert:Bool
   
    @State private var frozenTimeText: String = Date.now.formatted(date: .omitted, time: .shortened)

    @Namespace private var signalNS
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            @Bindable var data = data
            ZStack{
                ZStack {
                  
                    Image("background")
                        .resizable()
                        .ignoresSafeArea()
                        .overlay(data.finishStory ? Color.clear : Color.black.opacity(0.35))
                        .zIndex(-10)
                    
                    
                    BottomBarView(sizeofscreen: size, relayNS: signalNS)
                        .zIndex(9)
                    
                    
                    
                     NotificationsView(sizeOFScreen: size)
                         .zIndex(10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .top) {
                    MacToolbar(
                        sizeOFScreen: size,
                        frozenTimeText:data.finishStory ? Date.now.formatted(date: .omitted, time: .shortened): frozenTimeText,
                        cameraActive: true,
                        gestureModeActive: true,
                        stressLevel: data.finishStory ? .normal:.critical
                    )
                    .zIndex(12)
                }
                .overlay(content: {
                    if showHandAlert && !data.finishStory{
                        HandMissingOverlay()
                            .transition(.opacity)
                            .allowsHitTesting(false)
                    }

                })
                .overlay(content: {
                    if data.showSignalApp {
                                       SignalRelayAppFullscreen(
                                           ns: signalNS,
                                          
                                           onClose: {
                                               closeRelay()
                                               AudioManager.shared.stopBGM()
                                               self.data.finishedSendingEmergency()
                                           }
                                       )
                                      
                                   }
                })
                .overlay(content: {
                    if data.macSteps == .showBreakingNews{
                        BreakingNewsFinishView(onDone: {
                            withAnimation(.easeInOut(duration: 0.5)){
                                self.data.changeStartStep(.finishingScene)
                              
                            }
                        })
                    }
                })
                .onAppear {
                
                    frozenTimeText = Date.now.formatted(date: .omitted, time: .shortened)
                }
              
               
            }
        }
        
        
      
    }
    private func closeRelay() {
            withAnimation(.easeInOut(duration: 0.35)) {
                data.showSignalApp = false
            }
        }
}



struct MacToolbar: View {
    @Environment(ProjectData.self) var data

    let sizeOFScreen: CGSize
    let frozenTimeText: String

  
    let cameraActive: Bool
    let gestureModeActive: Bool
    let stressLevel: StressLevel

    enum StressLevel { case normal, warning, critical }

    @State private var batteryBlink = false
    @State private var camPulse = false
    @State private var dotGlow = false

    var body: some View {
        HStack(spacing: 14) {

         
            Image(systemName: "apple.logo")
                .foregroundStyle(.white.opacity(0.22))

            
            HStack(spacing: 8) {
                Text("Emergency Device")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))

            }

          
            ToolbarLabel("File")
            ToolbarLabel("Window")
            ToolbarLabel("Help")

            Spacer()

           
            if gestureModeActive {
                GestureModeChip()
                    .transition(.opacity)
            }

          
            HStack(spacing: 12) {

               
                if !data.finishStory{
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow.opacity(0.86))
                }
            
                ZStack {
                   
                        
                    if !data.finishStory{
                        Image(systemName: "wifi")
                            .foregroundStyle(.white.opacity(0.26))
                        Image(systemName: "line.diagonal")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.50))
                            .offset(x: 1)
                    }else{
                        Image(systemName: "wifi")
                            .foregroundStyle(.white)
                    }
                }
               
                
                if cameraActive {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green.opacity(dotGlow ? 0.95 : 0.55))
                            .frame(width: 7, height: 7)
                            .shadow(color: .green.opacity(dotGlow ? 0.45 : 0.20),
                                    radius: dotGlow ? 8 : 3)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                    dotGlow.toggle()
                                }
                            }

                        Text("Camera")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.60))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(.black.opacity(0.30))
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(.white.opacity(0.10), lineWidth: 1)
                            )
                    )
                }

              
                batteryView

               
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.20))

             
                Image(systemName: "switch.2")
                    .foregroundStyle(.white.opacity(0.20))

              
                Text(frozenTimeText)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .font(.system(size: 13, weight: .medium))
        .padding(.horizontal, 12)
        .frame(
            width: sizeOFScreen.width,
            height: max(26, sizeOFScreen.height / 55),
            alignment: .leading
        )
        .padding(.vertical, 6)
        .background(toolbarBackground)
        .allowsHitTesting(false)
        .onAppear {
            if stressLevel != .normal {
                withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true)) {
                    batteryBlink.toggle()
                }
            }
            if cameraActive {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    camPulse.toggle()
                }
            }
        }
    }

    private var batteryView: some View {
        let baseOpacity = stressLevel == .critical ? 0.95 : (stressLevel == .warning ? 0.65 : 0.35)
        let blinkOpacity = batteryBlink ? baseOpacity : max(0.18, baseOpacity - 0.55)

        return HStack(spacing: 6) {
            Image(systemName: stressLevel == .critical ? "battery.0percent" :
                    (stressLevel == .warning ? "battery.25percent" : "battery.100percent"))
            .foregroundStyle(stressLevel == .critical ? Color.red : Color.yellow.opacity(0.9))
            .opacity(stressLevel == .normal ? 0.28 : blinkOpacity)

           
        }
    }

    private var toolbarBackground: some View {
        ZStack {
           
            Color.black.opacity(0.62)

          
            Rectangle()
                .fill(.white.opacity(0.06))
                .frame(height: 1)
                .frame(maxHeight: .infinity, alignment: .bottom)

            if stressLevel == .critical {
                LinearGradient(
                    colors: [Color.red.opacity(camPulse ? 0.10 : 0.04), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blendMode(.screen)
                .opacity(0.8)
            }
        }
    }
}

private struct ToolbarLabel: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .foregroundStyle(.white.opacity(0.22))
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
    }
}

private struct GestureModeChip: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.70))

            Text("Gesture Mode")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.68))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(pulse ? 0.07 : 0.05))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse.toggle()
            }
        }
    }
}




struct BottomBarView: View {
    @Environment(ProjectData.self) var data
    let sizeofscreen:CGSize
    let relayNS:Namespace.ID
    var body: some View {
        
       
        HStack(spacing:15){
            DockIconDisabled(system: "face.smiling")
               
                .padding(.leading,5)
               
                        DockIconDisabled(system: "gearshape")
                
            if !data.finishStory{
                SignalRelayDockIcon(isActive: true, showBadge: true)
                    .matchedGeometryEffect(id: "signalRelayApp", in: relayNS)
                    .reportTargetFrame(.signalRelay, in: .named("sceneSpace"))
            }
        }
            .frame( height:70,alignment: .leading)
            
            .frame(minWidth:sizeofscreen.width / 2.5,alignment: .leading)
            .padding(10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray, lineWidth: 0.5)
            }
            .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .bottom)
            .transition(.move(edge: .bottom))
            .padding(10)
            .ignoresSafeArea()
           
        
    
       
    }
   
}
private struct DockIconDisabled: View {
    let system: String
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.03))
            .frame(width: 56, height: 56)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .overlay(
                Image(systemName: system)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.22))
            )
    }
}


struct SignalRelayDockIcon: View {
    var isActive: Bool = true
    var showBadge: Bool = true

    @State private var pulse = false
    @State private var shimmer = false

    var body: some View {
        ZStack {
          
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(width: 62, height: 62)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 10)

        
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.45, blue: 0.95).opacity(isActive ? 0.95 : 0.35),
                            Color(red: 0.06, green: 0.15, blue: 0.38).opacity(isActive ? 0.90 : 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(isActive ? 0.22 : 0.10), lineWidth: 1)
                )

           
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white.opacity(isActive ? 0.92 : 0.35))

         
            if isActive {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.0),
                                .white.opacity(0.18),
                                .white.opacity(0.0)
                            ],
                            startPoint: shimmer ? .topLeading : .bottomTrailing,
                            endPoint: shimmer ? .bottomTrailing : .topLeading
                        )
                    )
                    .frame(width: 56, height: 56)
                    .blendMode(.screen)
                    .opacity(0.55)
                    .allowsHitTesting(false)
            }

          
            if isActive {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(pulse ? 0.35 : 0.12), lineWidth: pulse ? 2 : 1)
                    .frame(width: 62, height: 62)
                    .blur(radius: pulse ? 2.5 : 1.0)
                    .shadow(color: Color(red: 0.20, green: 0.55, blue: 1.0).opacity(pulse ? 0.28 : 0.12),
                            radius: pulse ? 18 : 10)
                    .scaleEffect(pulse ? 1.04 : 0.98)
                    .allowsHitTesting(false)
            }

          
            if isActive && showBadge {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green.opacity(0.9))
                        .frame(width: 6, height: 6)
                        .shadow(color: .green.opacity(0.35), radius: 6)
                    Text("LIVE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.85))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Capsule(style: .continuous).fill(Color.white.opacity(0.92)))
                .offset(x: 0, y: 34)
                .shadow(color: .black.opacity(0.30), radius: 12, x: 0, y: 8)
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            if isActive {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulse.toggle()
                }
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    shimmer.toggle()
                }
            }
        }
        .accessibilityLabel("Signal Relay")
    }
}
