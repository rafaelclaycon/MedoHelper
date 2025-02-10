//
//  ReactionItem.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 01/02/25.
//

import SwiftUI
import Kingfisher

struct ReactionItem: View {

    let title: String
    let image: URL?
    let itemHeight: CGFloat
    let reduceTextSize: Bool

    @State private var isLoading: Bool = true

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.black.opacity(0.4))
            .frame(height: itemHeight)
            .background {
                KFImage(image)
                    .placeholder {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(2)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 45)
                                .foregroundColor(.gray)
                        }
                    }
                    .onSuccess { _ in isLoading = false }
                    .onFailure { _ in isLoading = false }
                    .resizable()
                    .scaledToFill()
                    .frame(height: itemHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .overlay {
                Text(title)
                    .foregroundColor(.white)
                    .font(reduceTextSize ? .title2 : .title)
                    .bold()
                    .multilineTextAlignment(.center)
                    .shadow(color: .black, radius: 4, y: 4)
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
