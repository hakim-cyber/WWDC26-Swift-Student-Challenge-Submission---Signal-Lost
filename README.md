
# Signal Lost 

YT: https://youtu.be/CultR87vsw4?si=w_qAHVK4x7ol4N_d

An immersive, real-time camera-driven interaction system built for the Swift Student Challenge.

Signal Lost explores a simple constraint: **what if touch input is unavailable?**  
Instead of treating accessibility as a secondary feature, this project makes touch-free interaction the core mechanic.

The entire experience is controlled using only the front-facing camera.

---

## 🎮 Experience Overview

The user is placed in an emergency scenario where traditional touch input is disabled.  
An emergency camera control mode activates automatically.

Interaction model:

- ✋ Hand movement → Controls a virtual cursor  
- 🤏 Pinch → Click / Drag  
- 🔓 Release pinch → Drop / Confirm  
- 🔄 Wrist rotation (while pinching) → Dial tuning  
- 👁 Eye blinks → Morse code (Short = dot, Long = dash)

### Story Flow

1. Connect a Mac power cable using pinch-based drag interaction  
2. Boot the system  
3. Navigate a signal relay interface  
4. Tune into the correct emergency frequency  
5. Transmit SOS using blink-based Morse code  
6. Receive rescue confirmation via simulated broadcast  

Touch input is intentionally blocked to preserve architectural integrity and narrative immersion.

---

## 🧠 Technical Architecture

Signal Lost is a real-time computer vision application processing ~30 FPS camera input.

### Vision Framework

- `VNDetectHumanHandPoseRequest` (21 hand joints per frame)
- Midpoint between thumb & index → Cursor mapping
- Distance threshold → Pinch detection
- Joint angle calculations → Wrist rotation
- `VNDetectFaceLandmarksRequest` → Eye contour extraction
- Eye Aspect Ratio (EAR) algorithm → Blink detection
- Adaptive blink calibration per user
- Exponential Moving Average (EMA) smoothing → Stable cursor motion

### AVFoundation

- `AVCaptureSession` camera pipeline
- `VNSequenceRequestHandler` for efficient frame processing
- Layered `AVAudioPlayer` system
- Crossfading background tracks
- Zero-latency gesture feedback sounds

### SwiftUI

- Fully programmatic UI
- Scene-driven state machine (`enum`-based progression)
- Custom virtual cursor hit-testing system
- CoordinateSpace interaction mapping
- 30 FPS reactive rendering using `@Observable`

### Concurrency

- Vision processing on background threads
- UI updates isolated to `@MainActor`
- Structured Swift Concurrency boundaries
- Safe data transfer between camera pipeline and UI layer

---

## 🏗 Custom Interaction System

Because the user does not physically touch the screen:

- Standard `.onTapGesture` cannot be used
- A custom hit-testing system was built
- Buttons report layout position
- Cursor coordinates are manually matched against view frames

This enables full virtual cursor simulation.

---

## ♿ Accessibility-First Design

Accessibility is the foundation, not an afterthought.

- No touch fallback
- Real-time visual feedback
- Audio confirmations for every action
- Adaptive blink thresholds
- Automatic progression timers to prevent user lock-in

The system is designed to remain usable even under physical limitation scenarios.

---

## 🚀 Why This Project Matters

Signal Lost demonstrates that:

- The front camera alone can replace touch interaction
- Vision + AVFoundation are capable of real-time multi-modal input
- Gesture-based UI can be implemented without additional hardware
- Accessibility can drive architecture rather than modify it

It brings visionOS-style spatial interaction concepts to a standard iPad environment.

---

## 🛠 Technologies Used

- Swift 5.9
- SwiftUI
- Vision Framework
- AVFoundation
- Swift Concurrency
- @Observable
- Custom mathematical filtering (EAR, EMA)

---

## 📌 Project Status

Built for Swift Student Challenge.  
Architected as a standalone interactive system.

---

## 👩‍💻 Author

Developed as an independent project exploring real-time computer vision interaction systems and accessibility-driven interface design.
# WWDC26-Swift-Student-Challenge-Submission---Signal-Lost
