import SwiftUI

struct ContentView: View {
    @State private var data = ProjectData()
    @State private var audio = AudioManager.shared
    var body: some View {
        VStack {
            StartView()
                .environment(data)
                .environment(audio)
                .onAppear {
                    audio.prime()
                    audio.playBGM(.startBackground, fade: 0.0)
                }
        }
    }
}
