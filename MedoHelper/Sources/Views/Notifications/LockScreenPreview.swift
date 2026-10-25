//
//  LockScreenPreview.swift
//  MedoHelper
//
//  Created by Claude on 25/10/26.
//

import SwiftUI

/// An iPhone lock screen showing the notification as it's being written.
struct LockScreenPreview: View {

    let title: String
    let message: String

    private static let ptBR = Locale(identifier: "pt_BR")

    var body: some View {
        PhoneFrame {
            TimelineView(.everyMinute) { context in
                screen(at: context.date)
            }
        }
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Prévia da notificação na tela bloqueada")
    }

    private func screen(at date: Date) -> some View {
        ZStack(alignment: .top) {
            wallpaper

            VStack(spacing: 0) {
                statusBar(at: date)

                Text(date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Self.ptBR)).capitalizedFirstLetter)
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.top, 34)

                Text(date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(Self.ptBR)))
                    .font(.system(size: 84, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .padding(.top, -6)

                Spacer()

                notification

                Spacer()
                    .frame(height: 90)

                bottomControls
            }
            .foregroundStyle(.white)
        }
    }

    // MARK: - Pieces

    private var wallpaper: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0], [0.55, 0], [1, 0],
                [0, 0.45], [0.6, 0.4], [1, 0.5],
                [0, 1], [0.45, 1], [1, 1]
            ],
            colors: [
                Color(red: 0.42, green: 0.62, blue: 0.66), Color(red: 0.2, green: 0.36, blue: 0.7), Color(red: 0.03, green: 0.07, blue: 0.24),
                Color(red: 0.5, green: 0.7, blue: 0.7), Color(red: 0.16, green: 0.3, blue: 0.68), Color(red: 0.06, green: 0.14, blue: 0.42),
                Color(red: 0.2, green: 0.52, blue: 0.54), Color(red: 0.08, green: 0.26, blue: 0.56), Color(red: 0.04, green: 0.1, blue: 0.36)
            ]
        )
    }

    private func statusBar(at date: Date) -> some View {
        HStack {
            Text(date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(Self.ptBR)))
                .monospacedDigit()
            Spacer()
            HStack(spacing: 5) {
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                Image(systemName: "battery.100")
            }
        }
        .font(.system(size: 14, weight: .semibold))
        .padding(.horizontal, 30)
        .padding(.top, 15)
    }

    private var notification: some View {
        HStack(alignment: .center, spacing: 11) {
            Image("MedoAppIcon")
                .resizable()
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title.isEmpty ? "Título" : title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                        .opacity(title.isEmpty ? 0.5 : 1)
                    Spacer(minLength: 6)
                    Text("agora")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
                // The lock screen cuts the body at four lines.
                Text(message.isEmpty ? "Texto da notificação" : message)
                    .font(.system(size: 15))
                    .lineLimit(4)
                    .opacity(message.isEmpty ? 0.5 : 1)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackground(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 10)
        .animation(.snappy, value: message.isEmpty)
    }

    private var bottomControls: some View {
        VStack(spacing: 18) {
            HStack {
                lockScreenButton(systemImage: "flashlight.off.fill")
                Spacer()
                lockScreenButton(systemImage: "camera.fill")
            }
            .padding(.horizontal, 44)

            Capsule()
                .fill(.white)
                .frame(width: 120, height: 5)
                .padding(.bottom, 8)
        }
    }

    private func lockScreenButton(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 19))
            .frame(width: 48, height: 48)
            .glassBackground(in: Circle())
    }
}

private extension View {

    @ViewBuilder
    func glassBackground(in shape: some Shape) -> some View {
        if #available(macOS 26, iOS 26, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }
}

private extension String {

    /// "domingo, 25 de outubro" → "Domingo, 25 de outubro", like the lock screen.
    var capitalizedFirstLetter: String {
        prefix(1).uppercased() + dropFirst()
    }
}

#Preview {
    LockScreenPreview(
        title: "Amanhã tem apuração do 2º turno",
        message: "Depois de votar, abra o app a partir das 17h para acompanhar a contagem ao vivo."
    )
    .padding(40)
}
