//
//  AudioModifiers.swift
//  SignalLost
//


import SwiftUI

struct SceneBGM: ViewModifier {
    @Environment(AudioManager.self) private var audio
    let track: BGMTrack?
    let fade: TimeInterval

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard let track else { audio.stopBGM(fade: fade); return }
                audio.playBGM(track, fade: fade)
            }
    }
}

struct SceneSFXOnAppear: ViewModifier {
    @Environment(AudioManager.self) private var audio
    let sfx: SFX
    let volume: Float?

    func body(content: Content) -> some View {
        content.onAppear { audio.playSFX(sfx, volume: volume) }
    }
}

extension View {
 
    func sceneBGM(_ track: BGMTrack?, fade: TimeInterval = 0.6) -> some View {
        modifier(SceneBGM(track: track, fade: fade))
    }

   
    func sceneSFXOnAppear(_ sfx: SFX, volume: Float? = nil) -> some View {
        modifier(SceneSFXOnAppear(sfx: sfx, volume: volume))
    }
}
