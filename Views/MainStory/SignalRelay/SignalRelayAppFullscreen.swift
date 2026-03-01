
//
//  SignalRelayAppFullscreen.swift
//  SignalLost
//
//  Created by aplle on 1/25/26.
//


import SwiftUI

struct SignalRelayAppFullscreen: View {
    let ns: Namespace.ID
   
    let onClose: () -> Void

    @State private var appeared = false
    @State private var showMorse = false

    var body: some View {
        ZStack {
            
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .opacity(appeared ? 1 : 0)
                .animation(.easeInOut(duration: 0.25), value: appeared)

           
            ZStack(alignment: .top) {
                Color.black
                
                if showMorse{
                    EyeMorseFinalView{
                        self.onClose()
                    }
                }else{
                    SignalRelayManualTuningView {
                        withAnimation(.easeInOut(duration: 0.35)){
                            self.showMorse = true
                        }
                    }
                }

             
            }
            .matchedGeometryEffect(id: "signalRelayApp", in: ns)
            .animation(.easeInOut(duration: 0.25), value: appeared)
            
        }
        .sceneBGM(.radioBackground, fade: 0.5)
        
    }
}
