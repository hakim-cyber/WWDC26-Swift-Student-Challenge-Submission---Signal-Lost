//
//  NotificationsView.swift
//  SignalLost
//
//  Created by aplle on 1/29/26.
//
import SwiftUI

struct NotificationsView: View {
    @Environment(ProjectData.self) var data
    let sizeOFScreen: CGSize
    @State private var showAlert: Bool = false

    var body: some View {
        let screenW = sizeOFScreen.width
        let screenH = sizeOFScreen.height
        let minSide = min(screenW, screenH)

        
        let cardW = clamp(screenW * 0.40, min: 280, max: 420)

      
        let pad = clamp(cardW * 0.055, min: 12, max: 20)
        let corner = clamp(cardW * 0.055, min: 14, max: 22)
        let gap = clamp(cardW * 0.035, min: 10, max: 14)

        let icon = clamp(cardW * 0.11, min: 26, max: 40)

        let titleSize = clamp(cardW * 0.050, min: 14, max: 18)
        let bodySize  = clamp(cardW * 0.040, min: 12, max: 15)
        let timeSize  = clamp(cardW * 0.034, min: 11, max: 13)

        VStack(alignment: .trailing, spacing: clamp(minSide * 0.012, min: 8, max: 12)) {
            ForEach(data.notifications) { notification in
                HStack(alignment: .top, spacing: gap) {

                    notification.image
                        .resizable()
                        .scaledToFit()
                        .frame(width: icon, height: icon)
                        .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(notification.title)
                                .font(.system(size: titleSize, weight: .heavy))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Spacer(minLength: 10)

                            Text(notification.date.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: timeSize, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Text(notification.body)
                            .font(.system(size: bodySize, weight: .medium))
                            .foregroundStyle(.primary.opacity(0.88))
                            .multilineTextAlignment(.leading)
                            .lineLimit(4)                
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .padding(pad)
                .frame(width: cardW, alignment: .leading)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.20), radius: 12, x: 0, y: 10)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .opacity))
            }
        }
        .padding(.top, clamp(minSide * 0.02, min: 12, max: 22))
        .padding(.trailing, clamp(minSide * 0.02, min: 12, max: 22))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .animation(.easeInOut(duration: 0.28), value: data.notifications)

        .onChange(of: data.notifications.count) { oldValue, newValue in
            if oldValue < newValue { showAlert = true }
        }
    }

    private func clamp(_ x: CGFloat, min lo: CGFloat, max hi: CGFloat) -> CGFloat {
        Swift.min(hi, Swift.max(lo, x))
    }
}
struct NotificationStruct:Identifiable,Equatable{
    var id : UUID = UUID()
    var image:Image
    var date: Date = Date()
    var title: String
    var body: String
  
}
