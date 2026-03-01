//
//  SwiftUIView.swift
//  Swift-Student-Challenge-2026-Distinguished
//
//  Created by aplle on 1/14/26.
//

import SwiftUI
import AVFoundation


struct BootScreenView: View {
    @State private var vm = CameraPermissionVM()
    @Environment(AudioManager.self) var audioManager
    var done: @MainActor () -> Void
    var body: some View {
        ZStack {
          
            Color.black.ignoresSafeArea()

         
            Scanlines()
                .blendMode(.screen)
                .opacity(0.4)
                .ignoresSafeArea()

        
            RadialGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.06), Color.clear]),
                center: .center,
                startRadius: 40,
                endRadius: 520
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 40)

             
                VStack(spacing: 10) {
                    Text("SIGNAL LOST")
                        .font(.system(size: 44, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.green)
                        .shadow(color: .green.opacity(0.35), radius: 16, x: 0, y: 0)

                    Text("Emergency Communication Simulator")
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.green.opacity(0.85))
                        .padding(.top, 2)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.green.opacity(0.35), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.green.opacity(0.05))
                        )
                )
                .overlay(
                  
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.green.opacity(0.18), lineWidth: 6)
                        .blur(radius: 10)
                        .opacity(0.6)
                )

              
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(vm.statusDotColor)
                            .frame(width: 10, height: 10)
                            .shadow(color: vm.statusDotColor.opacity(0.6), radius: 8)

                        Text(vm.statusTitle)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.green.opacity(0.95))

                        Spacer()

                        if vm.isRequesting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.green)
                                .scaleEffect(0.85)
                        }
                    }

                    Text(vm.statusDetail)
                        .font(.system(size: 12.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.green.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()
                        .background(Color.green.opacity(0.22))

                  
                    HStack(spacing: 12) {
                        Button {
                          
                            Task { @MainActor in
                                
                                if vm.state == .authorized {
                                    audioManager.playSFX(.confirm)
                                    done()
                                    return
                                } else {
                                    audioManager.playSFX(.click)
                                }
                                
                              
                                let granted = await vm.requestCamera()
                                
                             
                                if granted {
                                    audioManager.playSFX(.confirm)
                                    
                                    done()
                                } else {
                                   
                                    vm.refreshStatus()
                                }
                            }
                       
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(vm.primaryButtonTitle)
                                    .font(.system(size: 13.5, weight: .semibold, design: .monospaced))
                            }
                            .foregroundStyle(.black)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.green)
                            )
                            .shadow(color: .green.opacity(0.35), radius: 14, x: 0, y: 0)
                        }
                        .disabled(vm.primaryButtonDisabled)

                        if vm.showSettingsButton {
                            Button {
                                audioManager.playSFX(.click)
                                vm.openSettings()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("OPEN SETTINGS")
                                        .font(.system(size: 13.5, weight: .semibold, design: .monospaced))
                                }
                                .foregroundStyle(Color.green)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.green.opacity(0.55), lineWidth: 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(Color.green.opacity(0.06))
                                        )
                                )
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.green.opacity(0.25), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .frame(width: 400)

                Spacer()

            
                VStack(spacing: 6) {
                    Text(vm.footerLine)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.green.opacity(0.65))

                    Text("On-device processing • No data stored")
                        .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.green.opacity(0.45))
                }
                .padding(.bottom, 26)
            }
        }
        .onAppear {
            vm.refreshStatus()
        }
    }
}


@Observable
@MainActor
final class CameraPermissionVM {
    enum State {
        case unknown
        case notDetermined
        case authorized
        case denied
        case restricted
    }

     private(set) var state: State = .unknown
     var isRequesting: Bool = false

    func refreshStatus() {
        let s = AVCaptureDevice.authorizationStatus(for: .video)
        switch s {
        case .authorized: state = .authorized
        case .notDetermined: state = .notDetermined
        case .denied: state = .denied
        case .restricted: state = .restricted
        @unknown default: state = .unknown
        }
    }

    @MainActor
    func requestCamera() async -> Bool {
        refreshStatus()
        if state == .authorized { return true }
        guard state == .notDetermined else { return false }
        
        if isRequesting { return false }
        isRequesting = true
        
        let granted: Bool = await AVCaptureDevice.requestAccess(for: .video)
        
        isRequesting = false
        refreshStatus()
        return granted
    }
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

   

    var statusTitle: String {
        switch state {
        case .authorized: return "ACCESS GRANTED"
        case .notDetermined: return "CAMERA REQUIRED"
        case .denied: return "ACCESS DENIED"
        case .restricted: return "ACCESS RESTRICTED"
        case .unknown: return "STATUS UNKNOWN"
        }
    }

    var statusDetail: String {
        switch state {
        case .authorized:
            return "Video input online. Gesture pipeline ready.\nProceed to begin the emergency mission."
        case .notDetermined:
            return "To enable optical controls, the simulator needs camera input.\nPress INIT to request access."
        case .denied:
            return "Camera permission was denied.\nEnable it in Settings to continue."
        case .restricted:
            return "Camera access is restricted by system policy (e.g., Screen Time / MDM).\nTry another device or adjust restrictions."
        case .unknown:
            return "Unable to read camera authorization status.\nTry restarting the app."
        }
    }

    var footerLine: String {
        switch state {
        case .authorized: return "> system:  OK"
        case .notDetermined: return "> waiting: authorization request"
        case .denied: return "> error: permission blocked"
        case .restricted: return "> error: restricted by policy"
        case .unknown: return "> warning: unknown state"
        }
    }

    var statusDotColor: Color {
        switch state {
        case .authorized: return .green
        case .notDetermined: return .yellow
        case .denied, .restricted: return .red
        case .unknown: return .gray
        }
    }

    var primaryButtonTitle: String {
        switch state {
        case .notDetermined: return isRequesting ? "REQUESTING…" : "INIT CAMERA"
        case .authorized: return "Begin Mission"
        case .denied: return "PERMISSION NEEDED"
        case .restricted: return "UNAVAILABLE"
        case .unknown: return "RETRY"
        }
    }

    var primaryButtonDisabled: Bool {
        switch state {
        case .notDetermined: return isRequesting
        case .authorized: return false
        case .denied: return true
        case .restricted: return true
        case .unknown: return true
        }
    }

    var showSettingsButton: Bool {
        state == .denied
    }
}



private struct Scanlines: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let lineHeight: CGFloat = 3
                var y: CGFloat = 0

                while y < size.height {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    context.fill(Path(rect), with: .color(.green.opacity(0.12)))
                    y += lineHeight
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
    }
}

