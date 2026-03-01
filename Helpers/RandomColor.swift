import SwiftUI

extension Color {
    static func random(
        brightness: ClosedRange<Double> = 0.5...0.9,
        saturation: ClosedRange<Double> = 0.6...0.9
    ) -> Color {
        let hue = Double.random(in: 0...1)
        let sat = Double.random(in: saturation)
        let bri = Double.random(in: brightness)
        return Color(hue: hue, saturation: sat, brightness: bri)
    }
}
