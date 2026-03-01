//
//  EmergencyDeskBackground.swift
//  SignalLost
//
//  Created by aplle on 1/23/26.
//
import SwiftUI


struct EmergencyDeskBackground: View {

    let viewSize: CGSize

    var body: some View {
        ZStack {
           
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.02, green: 0.03, blue: 0.06),
                    Color(red: 0.03, green: 0.05, blue: 0.08),
                    Color(red: 0.02, green: 0.04, blue: 0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        
            RadialGradient(
                colors: [
                    Color(red: 0.12, green: 0.14, blue: 0.22).opacity(0.35),
                    Color(red: 0.06, green: 0.08, blue: 0.12).opacity(0.15),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.25),
                startRadius: 0,
                endRadius: viewSize.width * 0.85
            )


          
            VStack(spacing: 0) {
                Spacer()
                ZStack(alignment: .bottom) {
                  
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.12, blue: 0.14),
                            Color(red: 0.07, green: 0.09, blue: 0.11),
                            Color(red: 0.05, green: 0.07, blue: 0.09)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: viewSize.height * 0.42)

                 
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.03),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 4)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .frame(height: viewSize.height * 0.42)
            }

            
            RadialGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.25),
                    Color.black.opacity(0.55)
                ],
                center: .center,
                startRadius: viewSize.width * 0.35,
                endRadius: viewSize.width * 0.85
            )

        }
        
    }
}
