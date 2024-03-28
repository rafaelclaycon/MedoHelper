//
//  ExternalLinkButton.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 26/03/24.
//

import SwiftUI

struct ExternalLinkButton: View {

    let title: String
    let color: Color
    let symbol: String
    let link: String
    let onTapAction: (ExternalLink) -> Void

    var imageUrl: URL {
        URL(string: "\(baseURL)images/\(symbol)")!
    }

    var body: some View {
        Button {
            onTapAction(.init(symbol: symbol, title: title, color: color.toString(), link: link))
        } label: {
            HStack(spacing: 10) {
                AsyncImage(url: imageUrl) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .scaledToFit()
                .frame(width: 22)

                Text(title)
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
        }
        .capsule(colored: color)
    }
}

#Preview {
    ExternalLinkButton(
        title: "YouTube",
        color: .red,
        symbol: "youtube-a.png",
        link: "https://www.youtube.com/@CasimiroMiguel",
        onTapAction: { _ in }
    )
}
