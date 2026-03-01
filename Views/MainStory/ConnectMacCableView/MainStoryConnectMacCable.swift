//
//  IMacPowerCableScene.swift
//  SignalLost
//
//

import SwiftUI

struct IMacPowerCableScene: View {

    @State private var vm = ConnectMacCableVM()

    @State private var isPlugged = false
    @State private var frames: [SceneAnchor: CGRect] = [:]

  
    private let socketXRatio: CGFloat = 0.4
    private let socketYRatio: CGFloat = 0.6

    var onPlugged: () -> Void

   
    @State private var showHelp: Bool = true
    @State private var helpOpacity: Double = 0.0

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                EmergencyDeskBackground(viewSize: size)
                    .ignoresSafeArea()

             
                let macW = size.width * 0.44
                let macH = size.height * 0.72

                iMacView {
                    IMacFirmwareBatteryView(
                        fillRatio: isPlugged ? 0.85 : 0.18,
                        isPlugged: isPlugged
                    )
                }
                .frame(width: macW, height: macH, alignment: .bottom)
                .rotation3DEffect(.degrees(-6), axis: (x: 1, y: 0, z: 0), anchor: .bottom)
                .position(x: size.width * 0.3, y: size.height * 0.36)
                .reportFrame(.imac, in: .named("deskSpace"))
                .shadow(color: .black.opacity(0.40), radius: 30, x: 0, y: 22)
                .zIndex(1)

              
                if let imacFrame = frames[.imac], imacFrame != .zero {

                    let socketPoint = CGPoint(
                        x: imacFrame.minX + imacFrame.width  * socketXRatio,
                        y: imacFrame.minY + imacFrame.height * socketYRatio
                    )

                   
                    let outletPoint = CGPoint(
                        x: size.width * 0.72,
                        y: size.height * 0.47
                    )

                
                    Color.clear
                        .onAppear { vm.setFixedTarget(outletPoint, in: size) }
                        .onChange(of: size) { _, new in vm.setFixedTarget(outletPoint, in: new) }

                
                    CableBehindLayer(
                        socketPoint: socketPoint,
                        movablePoint: vm.movableEnd.pos(in: size),
                        isNear: vm.isNear,
                        isConnected: vm.isConnected,
                        isGrabbed: vm.isGrabbed
                    )
                    .zIndex(0)

                   
                    CableFrontLayer(
                        vm: vm,
                        socketPoint: socketPoint,
                        outletPoint: outletPoint,
                        sceneSize: size
                    ) {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            isPlugged = true
                        }
                      
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showHelp = false
                            helpOpacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.onPlugged()
                        }
                    }
                    .zIndex(2)

                
                }
            }
            .coordinateSpace(name: "deskSpace")
            .onPreferenceChange(AnchorFramesKey.self) { frames = $0 }
            .overlay(alignment: .topTrailing, content: {
                if showHelp && !vm.isConnected {
                    CableHelpOverlay(
                        footerText: vm.footerText,
                        showHandAlert: vm.showHandAlert, width:size.width / 5
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showHelp = false
                            helpOpacity = 0
                        }
                    }
                    .padding(.top, 22)
                    .padding(.trailing, 22)
                    .opacity(helpOpacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.45)) {
                            helpOpacity = 1.0
                        }
                      
                       
                    }
                }
            })
            .task { await vm.start() }
            .onDisappear { vm.stop() }
        }
    }
}



private struct CableHelpOverlay: View {
    let footerText: String
    let showHandAlert: Bool
    let width:CGFloat
    var onDismiss: () -> Void

    var body: some View {
        HelpOverlayCard(
            headerIcon: "exclamationmark.triangle.fill",
            headerIconColor: .yellow,
            title: "Emergency Power Link",
            bodyText: """
            The device is running on reserve power.
            Standard input is unavailable — optical hand control is active.
            Connect the loose cable end to restore stable power.
            """,
            tips: [
                .init(icon: "hand.raised.fill", text: "Keep your hand fully in frame."),
                .init(icon: "circle.dashed", text: "Move cursor to the plug, then pinch/click to grab."),
                .init(icon: "arrow.right.circle.fill", text: "Drag the plug to the outlet on the right."),
                .init(icon: "bolt.fill", text: "When the ring appears, pinch again to connect.")
            ],
            footerLeft: showHandAlert ? "> no hand detected" : footerText,
            footerRight: "Gesture Mode",
            width: width,
            showsClose: true,
            onDismiss: onDismiss
        )
    }
}




private struct CableBehindLayer: View {
    let socketPoint: CGPoint
    let movablePoint: CGPoint
    let isNear: Bool
    let isConnected: Bool
    let isGrabbed: Bool

    var body: some View {
        CableCurveFlat(
            a: socketPoint,
            b: movablePoint,
            bulge: isGrabbed ? 0.22 : 0.16,
            isNear: isNear,
            isConnected: isConnected
        )
        .allowsHitTesting(false)
        .opacity(0.95)
    }
}

private struct CableFrontLayer: View {

    @Bindable var vm: ConnectMacCableVM

    let socketPoint: CGPoint
    let outletPoint: CGPoint
    let sceneSize: CGSize
    let onConnected: () -> Void

    var body: some View {
        ZStack {
            WallOutletView()
                .position(outletPoint)
                .allowsHitTesting(false)

            FlatPlugView(
                isGrabbed: vm.isGrabbed,
                isHover: vm.isHoveringMovable,
                isConnected: vm.isConnected
            )
            .position(vm.movableEnd.pos(in: sceneSize))
            .allowsHitTesting(false)

            if vm.isNear && !vm.isConnected {
                MagneticRing()
                    .position(outletPoint)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            if (vm.isNear || vm.isConnected) && !vm.isGrabbed {
                SparksView()
                    .position(outletPoint)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            if let c = vm.cursorNormalized {
                CursorDot(isActive: vm.isGrabbed || vm.isPinched)
                    .position(x: c.x * sceneSize.width, y: c.y * sceneSize.height)
                    .allowsHitTesting(false)
            }

            if vm.showHandAlert {
                HandMissingOverlay()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            VStack {
                Spacer()
                Text(vm.footerText)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.65))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Capsule(style: .continuous).fill(Color.white.opacity(0.65)))
                    .padding(.bottom, 26)
            }
            .allowsHitTesting(false)
        }
        .onChange(of: vm.clicks) { _, _ in
            vm.handleClick(in: sceneSize)
        }
        .onChange(of: vm.cursorNormalized) { _, _ in
            vm.updateDragAndHover(in: sceneSize)
        }
        .onChange(of: vm.isConnected) { _, new in
            if new { onConnected() }
        }
    }
}





struct WallOutletView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.26, green: 0.34, blue: 0.44))
                .frame(width: 72, height: 230)
                .shadow(color: .black.opacity(0.22), radius: 10, x: 0, y: 10)

            VStack(spacing: 14) {
                OutletCell(twoHoles: false)
                OutletCell(twoHoles: true)
               
                OutletCell(twoHoles: false)
            }
            .padding(.vertical, 14)
        }
        .allowsHitTesting(false)
    }
}

private struct OutletCell: View {
    let twoHoles: Bool
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(red: 0.12, green: 0.16, blue: 0.22))
                .frame(width: 54, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                )

            if twoHoles {
                VStack(spacing: 10) {
                    Circle().fill(.white.opacity(0.22)).frame(width: 8, height: 8)
                    Circle().fill(.white.opacity(0.22)).frame(width: 8, height: 8)
                }
            } else {
                HStack(spacing: 12){
                    
                    Circle().fill(.white.opacity(0.22)).frame(width: 8, height: 8)
                    VStack(spacing: 12){
                        Circle().fill(.white.opacity(0.22)).frame(width: 8, height: 8)
                            
                        Circle().fill(.white.opacity(0.22)).frame(width: 8, height: 8)
                       
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct FlatPlugView: View {
    let isGrabbed: Bool
    let isHover: Bool
    let isConnected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.56, green: 0.70, blue: 0.86))
                .frame(width: 100, height: 56)
                .shadow(color: .black.opacity(0.28), radius: 12, x: 0, y: 10)

            VStack(spacing: 10) {
                Circle().fill(.black.opacity(0.30)).frame(width: 8, height: 8)
                Circle().fill(.black.opacity(0.30)).frame(width: 8, height: 8)
            }
        }
        .scaleEffect(isConnected ? 1.0 : (isGrabbed ? 1.04 : (isHover ? 1.02 : 1.0)))
        .animation(.easeInOut(duration: 0.12), value: isGrabbed)
        .animation(.easeInOut(duration: 0.12), value: isHover)
        .allowsHitTesting(false)
    }
}

struct CableCurveFlat: View {
    let a: CGPoint
    let b: CGPoint
    let bulge: CGFloat
    let isNear: Bool
    let isConnected: Bool

    var body: some View {
        let path = cubicCablePath(from: a, to: b, bulge: bulge)

        path
            .stroke(
                Color(red: 0.50, green: 0.62, blue: 0.78).opacity(isConnected ? 0.95 : (isNear ? 0.92 : 0.90)),
                style: StrokeStyle(lineWidth: isConnected ? 18 : 14, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
            .overlay(
            
                path.stroke(
                    .white.opacity(0.18),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                )
                .blendMode(.softLight)
                .offset(x: 0, y: -1)
            )
            .animation(.easeInOut(duration: 0.18), value: isNear)
            .animation(.easeInOut(duration: 0.18), value: isConnected)
            .allowsHitTesting(false)
    }

    private func cubicCablePath(from a: CGPoint, to b: CGPoint, bulge: CGFloat) -> Path {
        var p = Path()
        p.move(to: a)

        let dx = b.x - a.x
        let dy = b.y - a.y
        let len = max(1, hypot(dx, dy))
        let nx = -dy / len
        let ny = dx / len

        let amount = min(220, max(90, len * 0.32)) * bulge

        let c1 = CGPoint(x: a.x + dx * 0.33 + nx * amount,
                         y: a.y + dy * 0.33 + ny * amount)

        let c2 = CGPoint(x: a.x + dx * 0.66 + nx * amount,
                         y: a.y + dy * 0.66 + ny * amount)

        p.addCurve(to: b, control1: c1, control2: c2)
        return p
    }
}

struct MagneticRing: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.30), lineWidth: 2)
                .frame(width: 92, height: 92)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 12)
                .frame(width: 92, height: 92)
                .blur(radius: 14)
        }
        .scaleEffect(pulse ? 1.04 : 0.98)
        .opacity(pulse ? 1.0 : 0.85)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                pulse.toggle()
            }
        }
        .allowsHitTesting(false)
    }
}



struct SparksView: View {
    var body: some View {
        ZStack {
            Spark().rotationEffect(.degrees(-10)).offset(x: 54, y: -20)
            Spark().scaleEffect(0.9).rotationEffect(.degrees(6)).offset(x: 58, y: 10)
            Spark().scaleEffect(0.75).rotationEffect(.degrees(18)).offset(x: 42, y: 34)
        }
        .allowsHitTesting(false)
    }
}

private struct Spark: View {
    @State private var on = false

    var body: some View {
        SparkShape()
            .stroke(.white.opacity(on ? 0.80 : 0.18), lineWidth: 3)
            .shadow(color: .white.opacity(on ? 0.30 : 0.0), radius: 10, x: 0, y: 0)
            .frame(width: 26, height: 18)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true)) {
                    on.toggle()
                }
            }
    }
}

private struct SparkShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height

        p.move(to: CGPoint(x: w * 0.05, y: h * 0.58))
        p.addLine(to: CGPoint(x: w * 0.38, y: h * 0.18))
        p.addLine(to: CGPoint(x: w * 0.34, y: h * 0.50))
        p.addLine(to: CGPoint(x: w * 0.95, y: h * 0.10))
        p.addLine(to: CGPoint(x: w * 0.62, y: h * 0.82))
        p.addLine(to: CGPoint(x: w * 0.68, y: h * 0.55))
        p.addLine(to: CGPoint(x: w * 0.05, y: h * 0.58))
        return p
    }
}


