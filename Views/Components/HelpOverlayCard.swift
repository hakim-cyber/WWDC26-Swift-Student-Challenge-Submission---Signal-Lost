//
//  HelpOverlayCard.swift
//  SignalLost
//
//  Created by aplle on 2/1/26.
//



import SwiftUI

struct HelpOverlayCard: View {

    struct Tip: Identifiable, Equatable {
        let id = UUID()
        let icon: String
        let text: String
    }

   
    let headerIcon: String
    let headerIconColor: Color
    let title: String

    
    let bodyText: String
    let tips: [Tip]

  
    let footerLeft: String
    let footerRight: String

    
    var width: CGFloat = 340

  
    var showsClose: Bool = true
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 10) {
                Image(systemName: headerIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(headerIconColor.opacity(0.95))

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))

                Spacer(minLength: 8)

                if showsClose {
                    Button(action: { onDismiss?() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(8)
                            .background(Circle().fill(.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(bodyText)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(tips) { tip in
                    TipRow(icon: tip.icon, text: tip.text)
                }
            }
            .padding(.top, 2)

            Divider().overlay(Color.white.opacity(0.12))

            HStack {
                Text(footerLeft)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.62))

                Spacer()

                Text(footerRight)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .padding(16)
        .frame(width: width + 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.45), radius: 30, x: 0, y: 18)
        )
        .accessibilityElement(children: .combine)
    }
}

struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.70))
                .frame(width: 20)

            Text(text)
                .font(.system(size: 14.5, weight: .regular))
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
