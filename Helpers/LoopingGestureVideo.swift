import SwiftUI
import AVKit
struct LoopingGestureVideo: View {
    let name: String
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                if let url = Bundle.main.url(forResource: name, withExtension: "mp4"){
                    let p = AVPlayer(url: url)
                    p.isMuted = true
                    p.actionAtItemEnd = .none
                    player = p
                    p.play()

                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: p.currentItem,
                        queue: .main
                    ) { _ in
                        p.seek(to: .zero)
                        p.play()
                    }
                }
            }
            .onDisappear { player?.pause() }
            .allowsHitTesting(false)
    }
}
