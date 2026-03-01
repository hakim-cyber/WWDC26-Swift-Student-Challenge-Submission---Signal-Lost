//
//  SwiftUIView.swift
//  SignalLost
//
//  Created by aplle on 1/21/26.
//

import SwiftUI
extension Color {
    static let softSkyBlue = Color(
        red: 189.0 / 255.0,
        green: 211.0 / 255.0,
        blue: 238.0 / 255.0
    )
}

struct IMacBezelView: View {
 
    var body: some View {
       Image("imacBezel")
            .resizable()
            .scaledToFit()
            .reportFrame(in: .named("imacBezel"))
            
            .colorMultiply(Color.softSkyBlue)
    }
}


struct IMacFirmwareBatteryView: View {

    let fillRatio: CGFloat
    let isPlugged: Bool

    private let amber = Color(red: 1.0, green: 0.55, blue: 0.15)

    @State private var pulse = false

    var body: some View {
        GeometryReader{geo in
            let size =  geo.size
            ZStack {
              
                Color.black
                
                VStack(spacing: 20) {
                    
                    FirmwareBatteryIcon(
                        fillRatio: fillRatio,
                        color: isPlugged ? Color.green : amber,
                        charging: isPlugged,
                        pulse: pulse, height: size.width / 21
                    )
                    .frame(width: size.width / 7, height:  size.width / 21)
                    
                    
                  
                    HStack(spacing: 6) {
                        if !isPlugged {
                            Image(systemName: "powerplug.fill")
                            
                            Image(systemName: "plus")
                        }
                        Image(systemName: "bolt.fill")
                    }
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.75))
                    
                }
            }
        }
        .onAppear {
            if isPlugged {
                startPulse()
            }
        }
        .onChange(of: isPlugged) { _, new in
            if new { startPulse() }
        }
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            pulse.toggle()
        }
    }
}
private struct FirmwareBatteryIcon: View {

    let fillRatio: CGFloat
    let color: Color
    let charging: Bool
    let pulse: Bool
    let height:CGFloat

    var body: some View {
        HStack(spacing: 4) {

            ZStack(alignment: .leading) {

                
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(Color.white.opacity(0.9), lineWidth: 1)

                
                GeometryReader { g in
                    let inset: CGFloat = 3
                    let innerWidth = g.size.width - inset * 2
                    let fillWidth = max(3, innerWidth * fillRatio)

                    Rectangle()
                        .fill(color)
                        .frame(width: fillWidth, height:max(0, g.size.height - inset * 2))
                        .position(
                            x: inset + fillWidth / 2,
                            y: g.size.height / 2
                        )
                        .opacity(charging ? (pulse ? 0.55 : 0.9) : 0.9)
                }
            }
            .frame(height: height)

           
            Rectangle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 3, height: height / 4)
        }
    }
}



struct iMacView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    @State private var imacBezelFrame: CGRect = .zero

    var body: some View {
        ZStack {
          
            let screenWidth  = 0.946 * imacBezelFrame.width
            let screenHeight = 0.6306 * imacBezelFrame.height
            let offsetFromTop: CGFloat = 0.0318 * imacBezelFrame.height

            content
                .frame(width: screenWidth, height: screenHeight)
                .offset(y: offsetFromTop)
                .frame(maxWidth: imacBezelFrame.width,
                       maxHeight: imacBezelFrame.height,
                       alignment: .top)
                .clipped()

            IMacBezelView()
               
                .reportFrame(in: .named("imacBezel"))

           
        }
        .coordinateSpace(name: "imacBezel")
        .onPreferenceChange(ViewFrameKey.self) { frame in
            imacBezelFrame = frame
        }
    }
}
