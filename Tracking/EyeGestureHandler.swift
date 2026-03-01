//
//  EyeGestureHandler.swift
//  SignalLost
//
//  Created by aplle on 2/3/26.
//

import Vision
import AVFoundation
import CoreGraphics

final class EyeGestureHandler {

    enum EyeSymbol:String { case dot, dash }

    var onSymbol:      (@MainActor (EyeSymbol) -> Void)?
    var onFacePresent: (@MainActor (Bool) -> Void)?
    var onEyeClosure:  (@MainActor (CGFloat) -> Void)?

    private let request  = VNDetectFaceLandmarksRequest()
    private let sequence = VNSequenceRequestHandler()

    private let dotMax:       CFTimeInterval = 0.30
    private let dashMin:      CFTimeInterval = 0.30
    private let minValid:     CFTimeInterval = 0.10
    private let emitCooldown: CFTimeInterval = 0.45

   
    private enum StableEyeState { case open, closed }
    private var stableState:    StableEyeState = .open
    private var candidateState: StableEyeState = .open
    private var candidateSince: CFTimeInterval  = 0
    private let debounce:       CFTimeInterval  = 0.08

    private var closeStart: CFTimeInterval?
    private var lastEmit:   CFTimeInterval = 0

    private var baselineEAR:           CGFloat? = nil
    private var baselineSamples:       Int      = 0
    private let baselineTargetSamples: Int      = 18
    private let baselineMaxEARClamp:   CGFloat  = 0.42

   
    private let closedRatio: CGFloat = 0.55
    private let openRatio:   CGFloat = 0.70

   
    private var earHistory:    [CGFloat] = []
    private let earHistoryMax: Int       = 60
    private var earStdDev:     CGFloat   = 0.04

   

    func reset() {
        baselineEAR     = nil
        baselineSamples = 0
        earHistory.removeAll()
        earStdDev       = 0.04
        stableState     = .open
        candidateState  = .open
        candidateSince  = 0
        closeStart      = nil
        lastEmit        = 0
    }

    
    func recalibrate() {
        baselineEAR     = nil
        baselineSamples = 0
        earHistory.removeAll()
        earStdDev       = 0.04
    }

    

    func process(sampleBuffer: CMSampleBuffer) {
        let now = CACurrentMediaTime()

        let handler = VNImageRequestHandler(
            cmSampleBuffer: sampleBuffer,
            orientation: .up,
            options: [:]
        )

        do {
            try handler.perform([request])

            guard
                let face      = request.results?.first,
                let landmarks = face.landmarks,
                let left      = landmarks.leftEye,
                let right     = landmarks.rightEye
            else {
                emitFacePresent(false)
                emitEyeClosure(0)
                reset()
                return
            }

            emitFacePresent(true)

            let ear = (eyeAspectRatio(left) + eyeAspectRatio(right)) * 0.5

            if baselineSamples == 0 {
                baselineEAR     = min(max(ear, 0.08), baselineMaxEARClamp)
                baselineSamples = 1
            } else if baselineSamples < baselineTargetSamples {
                let clamped = min(max(ear, 0.08), baselineMaxEARClamp)
                let current = baselineEAR!
                baselineEAR     = max(current, clamped) * 0.70 + current * 0.30
                baselineSamples += 1
            } else if ear > baselineEAR! * openRatio {
              
                baselineEAR = baselineEAR! * 0.995 + ear * 0.005
            }

            let base = baselineEAR ?? 0.25

            
            earHistory.append(ear)
            if earHistory.count > earHistoryMax { earHistory.removeFirst() }
            if earHistory.count > 10 {
                let mean     = earHistory.reduce(0, +) / CGFloat(earHistory.count)
                let variance = earHistory.map { pow($0 - mean, 2) }.reduce(0, +) / CGFloat(earHistory.count)
                earStdDev    = max(0.015, sqrt(variance))
            }

            
            let closure = clamp01(1 - (ear / max(0.001, base)))
            emitEyeClosure(closure)

            let isClosed: Bool
            let isOpen:   Bool
            if earHistory.count >= 20, earStdDev >= 0.01 {
                isClosed = ear < (base - earStdDev * 2.2)
                isOpen   = ear > (base - earStdDev * 1.0)
            } else {
                isClosed = ear < base * closedRatio
                isOpen   = ear > base * openRatio
            }

            let newCandidate: StableEyeState =
                isClosed ? .closed : (isOpen ? .open : candidateState)

            if newCandidate != candidateState {
                candidateState = newCandidate
                candidateSince = now
            }
            if stableState != candidateState, (now - candidateSince) >= debounce {
                let prev    = stableState
                stableState = candidateState
                handleTransition(from: prev, to: stableState, now: now)
            }

        } catch {
         
        }
    }

    

    private func handleTransition(from: StableEyeState, to: StableEyeState, now: CFTimeInterval) {
        switch (from, to) {
        case (.open, .closed):
            closeStart = now

        case (.closed, .open):
            guard let start = closeStart else { return }
            closeStart = nil

            let dur = now - start
            guard dur >= minValid               else { return }
            guard now - lastEmit >= emitCooldown else { return }

            if dur <= dotMax {
                emit(.dot, now)
            } else if dur >= dashMin {
                emit(.dash, now)
            }
            

        default:
            break
        }
    }

  

    private func emit(_ symbol: EyeSymbol, _ now: CFTimeInterval) {
        lastEmit = now
        let cb = onSymbol
        Task { @MainActor in cb?(symbol) }
    }

    private func emitFacePresent(_ present: Bool) {
        let cb = onFacePresent
        Task { @MainActor in cb?(present) }
    }

    private func emitEyeClosure(_ closure: CGFloat) {
        let cb = onEyeClosure
        Task { @MainActor in cb?(closure) }
    }

 

    private func eyeAspectRatio(_ eye: VNFaceLandmarkRegion2D) -> CGFloat {
        let pts = eye.normalizedPoints
        guard pts.count >= 6 else { return 0.25 }

        let p1 = pts[0]; let p2 = pts[1]; let p3 = pts[2]
        let p4 = pts[3]; let p5 = pts[4]; let p6 = pts[5]

        let v1 = dist(p2, p6)
        let v2 = dist(p3, p5)
        let h  = dist(p1, p4)

        if h < 0.0001 { return 0.25 }
        return (v1 + v2) / (2 * h)
    }

    private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    private func clamp01(_ x: CGFloat) -> CGFloat {
        min(1, max(0, x))
    }
}
