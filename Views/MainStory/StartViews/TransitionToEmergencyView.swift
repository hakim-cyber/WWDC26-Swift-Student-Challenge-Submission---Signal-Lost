import SwiftUI

struct TransitionToEmergencyTextView: View {
   @State private var vm = TransitionToEmergencyTextVM()
    var done: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            
               
                VStack(alignment: .leading, spacing: 12) {
                
                    if let l1 = vm.line1 { SystemLine(l1) }
                    if let l2 = vm.line2 { SystemLine(l2) }
                
                }
                
            
            
            .frame(alignment: .topLeading)
           
            .padding(28)
            .opacity(vm.textOpacity)
        }
       
        .task {
            await vm.run()
            done()
        }
    }
}

private struct SystemLine: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 25, weight: .regular, design: .monospaced))
            .foregroundStyle(.white.opacity(0.92))
    }
}

@Observable
@MainActor
final class TransitionToEmergencyTextVM {
     var line1: String?
     var line2: String?
     var textOpacity: Double = 0.0

    func run() async {
      
        withAnimation(.easeInOut(duration: 0.35)) { textOpacity = 1.0 }

      
        withAnimation(.easeInOut(duration: 0.35)) {
            line1 = "Setup complete."
        }
        AudioManager.shared.typeForLine(line1)
        try? await Task.sleep(nanoseconds: 900_000_000)

       
        try? await Task.sleep(nanoseconds: 400_000_000)

       
        withAnimation(.easeInOut(duration: 0.35)) {
            line2 = 
            """
            The computer has no power
            Restore power to continue.
            """
        }
        AudioManager.shared.typeForLine(line2)
        try? await Task.sleep(nanoseconds: 1_450_000_000)

       
        withAnimation(.easeInOut(duration: 0.55)) { textOpacity = 0.0 }
        try? await Task.sleep(nanoseconds: 600_000_000)
    }
}
