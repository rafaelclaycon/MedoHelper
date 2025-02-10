//
//  ExternalLinkButton.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 26/03/24.
//

import SwiftUI

struct ExternalLinkButton: View {

    let externalLink: ExternalLink
    let onTapAction: (ExternalLink) -> Void

    var imageUrl: URL {
        URL(string: "\(baseURL)images/\(externalLink.symbol)")!
    }

    var body: some View {
        Button {
            onTapAction(externalLink)
        } label: {
            HStack(spacing: 10) {
                AsyncImage(url: imageUrl) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .scaledToFit()
                .frame(width: 22)

                Text(externalLink.title)
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
        }
        .capsule(colored: externalLink.color.toColor())
    }
}

#Preview {
    ExternalLinkButton(
        externalLink: .init(
            symbol: "youtube-a.png",
            title: "YouTube",
            color: "red",
            link: "https://www.youtube.com/@CasimiroMiguel"
        ),
        onTapAction: { _ in }
    )
}
