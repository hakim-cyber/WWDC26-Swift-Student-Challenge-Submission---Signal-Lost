//
//  SwiftUIView.swift
//  SignalLost
//
//  Created by aplle on 1/25/26.
//

import SwiftUI

struct DesktopScene: View {
    @State private var vm = DesktopMouseTracker()
    @Environment(ProjectData.self) var data


    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                EmergencyDeskBackground(viewSize: size)
                    .ignoresSafeArea()

                iMacView {
                    DesktopView(showHandAlert: vm.showHandAlert)
                       
                }
                .allowsHitTesting(false)

              
                if !data.showSignalApp{
                    if let c = vm.cursorNormalized {
                        CursorDot(isActive: vm.isPinched)
                            .position(x: c.x * size.width, y: c.y * size.height)
                            .allowsHitTesting(false)
                    }
                    
                }
               
                if data.showTip, let relayFrame = data.desktopTargets[.signalRelay] {
                    StableSignalRelayTip(
                        relayFrame:  relayFrame
                    )
                    .transition(.opacity)
                    .allowsHitTesting(false)
                    .zIndex(100)
                }
            }
            .coordinateSpace(name: "sceneSpace")
            .onPreferenceChange(DesktopTargetFramesKey.self) { frames in
                data.desktopTargets = frames
            }
            
            .onChange(of: vm.clicks) { _, _ in
                handleClick(sceneSize: size)
            }
        }
        
        .onChange(of: data.showSignalApp, { oldValue, newValue in
            if newValue{
                self.vm.stop()
            }else{
                Task{
                    await vm.start()
                }
            }
        })
        .onAppear{
            Task{
                await vm.start()
            }
        }
       
        .onDisappear { vm.stop() }
    }

    private func handleClick(sceneSize: CGSize) {
        guard let c = vm.cursorNormalized else { return }
        let cursorPx = CGPoint(x: c.x * sceneSize.width, y: c.y * sceneSize.height)

        if let hit = hitTest(cursorPx) {
            route(hit)
        }
    }

    private func hitTest(_ p: CGPoint) -> DesktopTarget? {
        let priority: [DesktopTarget] = [.signalRelay]

        for t in priority {
            if let r = data.desktopTargets[t], r.contains(p) { return t }
        }
        return nil
    }

    private func route(_ target: DesktopTarget) {
        switch target {
        case .signalRelay:
           
            withAnimation(.easeInOut(duration: 0.35)) {
                data.showTip = false
                data.showSignalApp = true
              
                data.showSignalApp = true
                         
                        
            }

          
        }
    }
}

#Preview {
    DesktopScene()
}




import AVFoundation

@MainActor
@Observable
final class DesktopMouseTracker {

    var cursorNormalized: CGPoint? = nil
    var isPinched: Bool = false
    var clicks: Int = 0
    var showHandAlert: Bool = false

    private var lastHandSeen: CFTimeInterval = 0
    private let handMissingAfter: CFTimeInterval = 0.45

    private let tracker = HandMovementTracker()
    var session: AVCaptureSession { tracker.captureSession }

    private var started = false
    private var orientationObserver: NSObjectProtocol?

    func start() async {
        
        if started {
            tracker.start()
            return
        }
        started = true


        tracker.onCursor = { [weak self] p in
            guard let self else { return }
            self.cursorNormalized = p

            let now = CACurrentMediaTime()
            if p == nil {
                if (now - self.lastHandSeen) > self.handMissingAfter {
                    self.showHandAlert = true
                }
            } else {
                self.lastHandSeen = now
                self.showHandAlert = false
            }
        }

        tracker.onPinchChanged = { [weak self] pinched in
            self?.isPinched = pinched
        }

        tracker.onClick = { [weak self] in
            AudioManager.shared.playSFX(.click)
            self?.clicks += 1
        }

   
        if orientationObserver == nil {
            orientationObserver = NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.tracker.updateConnectionOrientation()
            }
        }

        tracker.start()
    }

    func stop() {
        tracker.stop()

      
        started = false

      
        cursorNormalized = nil
        isPinched = false
        showHandAlert = false

      
        tracker.onCursor = nil
        tracker.onPinchChanged = nil
        tracker.onClick = nil
    }
}
