//
//  BannerPhonePreview.swift
//  MedoHelper
//
//  Created by Claude on 25/10/26.
//

import SwiftUI

/// The banner at the top of Vírgulas on an iPhone. Laid out at the phone's real size so
/// paragraphs wrap where they will in the app.
struct BannerPhonePreview: View {

    let banner: DynamicBannerData
    @Binding var isExpanded: Bool
    let colorScheme: ColorScheme

    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?

    var body: some View {
        PhoneFrame(screenSize: CGSize(width: 393, height: 852), scale: 0.78) {
            screen
        }
        .environment(\.colorScheme, colorScheme)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Prévia do banner no iPhone")
    }

    private var screen: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusBar

            Text("Vírgulas")
                .font(.system(size: 34, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 16) {
                    BannerReplica(banner: banner, isExpanded: $isExpanded, onCopy: showToast)
                    placeholderGrid
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.never)
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .font(.system(size: 15, weight: .medium))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 44)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: toast)
    }

    // MARK: - Pieces

    private var statusBar: some View {
        HStack {
            Text("9:41")
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                Image(systemName: "battery.100")
            }
        }
        .font(.system(size: 17, weight: .semibold))
        .padding(.horizontal, 36)
        .padding(.top, 18)
        .frame(height: 54, alignment: .top)
    }

    /// Stand-ins for the sounds under the banner, just for context.
    private var placeholderGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(0..<10, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.gray.opacity(colorScheme == .dark ? 0.25 : 0.12))
                    .frame(height: 96)
            }
        }
    }

    private func showToast(_ message: String) {
        toastTask?.cancel()
        toast = message.isEmpty ? "Copiado!" : message
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }
}

/// Mirrors `DynamicBanner` in the app: same colors, symbol size, fonts and expanding
/// behavior, drawn with plain views because macOS styles disclosure groups and bordered
/// buttons differently from iOS.
private struct BannerReplica: View {

    let banner: DynamicBannerData
    @Binding var isExpanded: Bool
    let onCopy: (String) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let mainColor: Color = .pink

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: banner.symbol.isEmpty ? "questionmark.square.dashed" : banner.symbol)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)

                    Text(banner.title.isEmpty ? "Título do banner" : banner.title)
                        .font(.system(size: 16, weight: .bold))
                        .multilineTextAlignment(.leading)
                        .opacity(banner.title.isEmpty ? 0.5 : 1)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(banner.text.enumerated()), id: \.offset) { _, paragraph in
                        Text((try? AttributedString(markdown: paragraph)) ?? AttributedString())
                            .font(.system(size: 16))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(Array(banner.buttons.enumerated()), id: \.offset) { _, button in
                            Button {
                                if button.type == .copyText {
                                    onCopy(button.additionalData ?? "")
                                }
                            } label: {
                                Text(button.title.isEmpty ? "Botão" : button.title)
                                    .font(.system(size: 17))
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(mainColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .help(button.type == .openLink ? "Abre \(button.data)" : "Copia \"\(button.data)\"")
                        }
                    }
                    .padding(.top, 5)
                }
                .padding(.top)
                .transition(.opacity)
            }
        }
        .foregroundStyle(mainColor)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .foregroundStyle(mainColor)
                .opacity(colorScheme == .dark ? 0.3 : 0.15)
        }
    }
}

#Preview {
    BannerPhonePreview(
        banner: DynamicBannerData(
            symbol: "arrow.trianglehead.clockwise.heart.fill",
            title: "Em 2026, as doações caíram pela metade",
            text: [
                "Nos últimos meses, o app ganhou **transcrições, capítulos e jogos**.",
                "O que mais ajuda é um **Pix recorrente**. 💚"
            ],
            buttons: [
                DynamicBannerButton(title: "Copiar chave pra Pix recorrente", type: .copyText, data: "contato@medodelirioios.com", additionalData: "Chave copiada! 💚"),
                DynamicBannerButton(title: "Prefiro o Apoia.se", type: .openLink, data: "https://apoia.se/app-medo-delirio-ios", additionalData: nil)
            ]
        ),
        isExpanded: .constant(true),
        colorScheme: .light
    )
    .padding(40)
}
