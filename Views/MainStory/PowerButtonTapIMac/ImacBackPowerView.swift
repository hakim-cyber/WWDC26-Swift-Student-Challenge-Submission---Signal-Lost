
import SwiftUI
extension Color {
    static let macColor = Color(
        red: 73.0 / 255.0,
        green: 116.0 / 255.0,
        blue: 163.0 / 255.0
    )
  
        static let macAppleIconColor = Color(
            red: 172.0 / 255.0,
            green: 193.0 / 255.0,
            blue: 222.0 / 255.0
        )
    
}


struct ImacBackPowerView:View {
    @Environment(IMacPowerOnVM.self) var vm
    @Binding var isOn:Bool
    var body: some View {
        GeometryReader{geo in
            let size = geo.size
            ZStack{
                let width = min(size.width, size.height) * 0.8
                let height = width * 0.688
                RoundedRectangle(cornerRadius: width / 49)
                    .fill(Color.macColor)
                    .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: width / 49)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                        .frame(width:width,height:height)
                        .overlay(alignment:.center){
                          
                                Image(systemName: "apple.logo")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Color.macAppleIconColor)
                                    .shadow(
                                        color: .black.opacity(0.1),
                                        radius: 2,
                                        x: 0,
                                        y: 3
                                    )
                                   
                                    .frame(
                                        width: height * 0.191,
                                        height: height * 0.225
                                    )
                            
                                    .offset(
                                        
                                        y: -height * 0.107
                                    )
                            Group{
                                IMacInsetPowerButton(isOn: $isOn, size: 0.06*height)
                                    .onGeometryChange(for: CGRect.self, of: { geo in
                                        geo.frame(in: .named("macScene"))
                                    }, action: { newValue in
                                        print("Power button rect: \(newValue)")
                                        self.vm.powerButtonFrame = newValue
                                    })
                                    .offset(
                                        x:height*0.64
                                        )
                                    
                                HStack(spacing: width * 0.0225){
                                    IMacPort(width: 0.0067*height, height: 0.0241*height)
                                    IMacPort(width: 0.0067*height, height: 0.0241*height)
                                    IMacPort(width: 0.0067*height, height: 0.0241*height)
                                    IMacPort(width: 0.0067*height, height: 0.0241*height)
                                }
                                .offset(
                                    x:-height*0.45
                                    )
                            }
                                .offset(
                                   
                                    y: height * 0.41
                                )
                            VStack{
                                Spacer()
                                IMacStandSocket()
                                    .offset(y:5)
                            }
                            .clipped()
                         
                        }
               
              
            }
            .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .center)
        }
    }
}


struct IMacInsetPowerButton: View {
    @Binding var isOn:Bool
    var size: CGFloat = 44
    var action: () -> Void = {}


    var body: some View {
        let press = isOn

        ZStack {
            Circle()
                .fill(Color.macColor)

              
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(press ? 0.45 : 0.28), lineWidth: press ? 2.6 : 2.0)
                        .blur(radius: press ? 0.9 : 0.6)
                        .offset(x: press ? -1 : -0.8, y: press ? -1.2 : -0.8)
                        .mask(Circle())
                )
              
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(press ? 0.08 : 0.12), lineWidth: press ? 2.6 : 2.0)
                        .blur(radius: press ? 0.9 : 0.6)
                        .offset(x: press ? 1.2 : 0.8, y: press ? 1.2 : 0.8)
                        .mask(Circle())
                )
               
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.black.opacity(press ? 0.26 : 0.18),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: size * 0.75
                            )
                        )
                        .blendMode(.multiply)
                )

            Image(systemName: "power")
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundStyle(Color.macAppleIconColor)
                .offset(y: press ? 1 : 0)
                .shadow(color: .black.opacity(press ? 0.08 : 0.15),
                        radius: press ? 0.5 : 0.8,
                        x: 0, y: press ? 0.3 : 0.6)
        }
        .frame(width: size, height: size)
        
       
        .scaleEffect(press ? 0.97 : 1.0)
        .animation(.easeOut(duration: 0.10), value: press)
        .contentShape(Circle())
        
        
    }
}




struct IMacPort: View {
    var width: CGFloat = 10
    var height: CGFloat = 22
    var corner: CGFloat { width / 2 }

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Color.black.opacity(0.35))
           
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black.opacity(0.35), lineWidth: 2)
                    .blur(radius: 0.8)
                    .offset(x: -0.6, y: -0.6)
                    .mask(RoundedRectangle(cornerRadius: corner, style: .continuous))
            )
          
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1.5)
                    .blur(radius: 0.6)
                    .offset(x: 0.6, y: 0.6)
                    .mask(RoundedRectangle(cornerRadius: corner, style: .continuous))
            )
        
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.35),
                                Color.black.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.multiply)
            )
            .frame(width: width, height: height)
            .blur(radius: 0.15)
    }
}


struct IMacStandSocket: View {
    var standWidth: CGFloat = 260
    var standHeight: CGFloat = 180

    var capsuleWidth: CGFloat = 66
    var capsuleHeight: CGFloat = 140

    var socketSize: CGFloat = 44
    var cableWidth: CGFloat = 5
    var cableHeight: CGFloat = 140

    var body: some View {
        ZStack {
           
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.80),
                            Color.white.opacity(0.55),
                            Color.white.opacity(0.70)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                   
                    Rectangle()
                        .fill(Color.black.opacity(0.22))
                        .frame(height: 5)
                        .blur(radius: 2),
                    alignment: .top
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
                .frame(width: standWidth, height: standHeight)

           
            RoundedRectangle(cornerRadius: capsuleWidth / 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.22),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: capsuleWidth / 2, style: .continuous)
                        .fill(Color.blue.opacity(0.35))
                        .blendMode(.multiply)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: capsuleWidth / 2, style: .continuous)
                        .stroke(Color.black.opacity(0.18), lineWidth: 1)
                )
                .frame(width: capsuleWidth, height: capsuleHeight)
                .offset(y: 18)

           
            RoundedRectangle(cornerRadius: cableWidth / 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.90),
                            Color.white.opacity(0.65),
                            Color.white.opacity(0.85)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: cableWidth, height: cableHeight)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                .offset(y: 18 + (cableHeight / 2) + 12)

           
            ZStack {
              
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.85),
                                Color.black.opacity(0.25),
                                Color.white.opacity(0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.25), lineWidth: 1)
                    )


               
                Circle()
                    .inset(by: socketSize * 0.36)
                    .fill(Color.black.opacity(0.45))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

               
                Circle()
                    .fill(Color.white.opacity(0.20))
                    .frame(width: socketSize * 0.22, height: socketSize * 0.22)
                    .offset(x: -socketSize * 0.12, y: -socketSize * 0.12)
                    .blur(radius: 0.5)
            }
            .frame(width: socketSize, height: socketSize)
            .shadow(color: .black.opacity(0.20), radius: 2, x: 0, y: 1)
            .offset(y: 18)
        }
    }
}
