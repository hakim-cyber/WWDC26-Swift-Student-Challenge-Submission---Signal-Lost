//
//  AudioManager.swift
//  SignalLost


import SwiftUI
import AVFoundation



enum BGMTrack: String, CaseIterable {
    case startBackground = "startBackground"
    case newsBackground = "newsBackground"
    case mainStoryBackground = "mainStoryBackground"
    case finishBackground = "finishBackground"
    case radioBackground = "radioBackground"
  
}

enum SFX: String, CaseIterable {
    case click        = "clickSFX"
    case confirm        = "confirmSFX"
    case beep        = "beepSFX"
    case imacPowerSFX = "imacPowerSFX"
    case whoosh = "whoosh"
  case notificationSFX = "notificationSFX"
    case errorSFX = "errorSFX"

}



@Observable
@MainActor
final class AudioManager {

    static let shared = AudioManager()

 
   var bgmEnabled: Bool = true
    var sfxEnabled: Bool = true

  @ObservationIgnored  var bgmVolume: Float = 0.1
    @ObservationIgnored   var sfxVolume: Float = 0.9

    @ObservationIgnored  private var playerA: AVAudioPlayer?
    @ObservationIgnored   private var playerB: AVAudioPlayer?
    @ObservationIgnored  private var activeIsA: Bool = true
    @ObservationIgnored  private var currentBGM: BGMTrack?

  
    @ObservationIgnored   private var sfxPlayers: [SFX: AVAudioPlayer] = [:]
    
    @ObservationIgnored private var typingTask: Task<Void, Never>?
    @ObservationIgnored private var morseTask: Task<Void, Never>?

    private init() { configureAudioSession() }

   
    func prime() {
        preloadSFX()
       
    }
    func stopSFX(_ sound: SFX) {
        guard let p = sfxPlayers[sound] else { return }
        p.stop()
        p.currentTime = 0
    }

   

    func playBGM(_ track: BGMTrack, fade: TimeInterval = 0.6) {
        guard bgmEnabled else { return }
        if currentBGM == track { return }

        let next = makeBGMPlayer(track)
        next.numberOfLoops = -1
        next.volume = 0.0
        next.play()

    
        if activeIsA {
            playerB?.stop()
            playerB = next
            crossfade(from: playerA, to: playerB, duration: fade, target: bgmVolume)
        } else {
            playerA?.stop()
            playerA = next
            crossfade(from: playerB, to: playerA, duration: fade, target: bgmVolume)
        }

        activeIsA.toggle()
        currentBGM = track
    }

    func stopBGM(fade: TimeInterval = 0.4) {
        currentBGM = nil
        crossfade(from: activePlayer, to: nil, duration: fade, target: 0.0)
    }

    func setBGMEnabled(_ enabled: Bool) {
        bgmEnabled = enabled
        if !enabled { stopBGM(fade: 0.25) }
    }

    func setSFXEnabled(_ enabled: Bool) {
        sfxEnabled = enabled
    }

    func setBGMVolume(_ value: Float, animated: Bool = true) {
        bgmVolume = max(0, min(1, value))
        guard bgmEnabled else { return }
        let p = activePlayer
        if animated {
            fadeVolume(player: p, to: bgmVolume, duration: 0.25)
        } else {
            p?.volume = bgmVolume
        }
    }


    func playSFX(_ sound: SFX, volume: Float? = nil) {
        guard sfxEnabled else { return }
        guard let p = sfxPlayers[sound] else {
          
            if let oneOff = makeSFXPlayer(sound) {
                oneOff.volume = (volume ?? sfxVolume)
                oneOff.play()
            }
            return
        }

       
        p.currentTime = 0
        p.volume = (volume ?? sfxVolume)
        p.play()
    }
    
 
    @MainActor
    func startTypingTicks(count: Int, intervalMs: UInt64 = 55, tickLen: TimeInterval = 0.04, volume: Float = 0.46) {
        typingTask?.cancel()

        typingTask = Task { @MainActor in
            guard let p = sfxPlayers[.beep] else { return }

            for _ in 0..<count {
                if Task.isCancelled { break }

              
                p.stop()
                p.currentTime = 0.05
                p.volume = volume
                p.play()

                try? await Task.sleep(nanoseconds: UInt64(tickLen * 1_000_000_000))
                p.stop()
                p.currentTime = 0

                try? await Task.sleep(nanoseconds: intervalMs * 1_000_000)
            }
        }
    }

    @MainActor
    func typeForLine(_ text: String?) {
        guard let text else { return }
        let count = min(14, max(6, text.count / 5))
        startTypingTicks(count: count)
    }
    
 

 

    @MainActor
    func playDot(volume: Float? = nil) {
        playMorseBeep(duration: 0.30, volume: volume)
    }

    @MainActor
    func playDash(volume: Float? = nil) {
        playMorseBeep(duration: 0.60, volume: volume)
    }

    @MainActor
    private func playMorseBeep(duration: TimeInterval, volume: Float?) {
        guard sfxEnabled else { return }
        guard let p = sfxPlayers[.beep] else { return }

      
        morseTask?.cancel()

       
        p.stop()
        p.currentTime = 0.05
        p.volume = volume ?? sfxVolume
        p.play()

       
        morseTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if Task.isCancelled { return }
            self.stopSFX(.beep)
        }
    }
}



private extension AudioManager {

    var activePlayer: AVAudioPlayer? {
        activeIsA ? playerA : playerB
    }

    func configureAudioSession() {
        do {
          
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
        
            print("AudioSession error:", error.localizedDescription)
        }
    }

    func preloadSFX() {
        for sfx in SFX.allCases {
            if let p = makeSFXPlayer(sfx) {
                p.prepareToPlay()
                sfxPlayers[sfx] = p
            }
        }
    }

    func makeBGMPlayer(_ track: BGMTrack) -> AVAudioPlayer {
        guard let url = Bundle.main.url(forResource: track.rawValue, withExtension: "m4a") else {
            fatalError("Missing BGM file: \(track.rawValue).m4a")
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.isMeteringEnabled = false
            p.prepareToPlay()
            return p
        } catch {
            fatalError("Failed to load BGM \(track.rawValue): \(error)")
        }
    }

    func makeSFXPlayer(_ sound: SFX) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "m4a") else {
          
            return nil
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = 0
            p.volume = sfxVolume
            p.prepareToPlay()
            return p
        } catch {
            return nil
        }
    }

    func crossfade(from: AVAudioPlayer?, to: AVAudioPlayer?, duration: TimeInterval, target: Float) {
       
        if let from {
            fadeVolume(player: from, to: 0.0, duration: duration)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                from.stop()
            }
        }
      
        if let to {
            fadeVolume(player: to, to: target, duration: duration)
        }
    }

    func fadeVolume(player: AVAudioPlayer?, to target: Float, duration: TimeInterval) {
        guard let player else { return }
        let steps = max(1, Int(duration / 0.02))
        let start = player.volume
        let delta = (target - start) / Float(steps)

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(i) * 0.02)) {
                player.volume = start + (Float(i) * delta)
            }
        }
    }
}
