//
//  PhoneFrame.swift
//  MedoHelper
//
//  Created by Claude on 25/10/26.
//

import SwiftUI

/// An iPhone bezel with a Dynamic Island around whatever screen it's given.
///
/// The screen is laid out at `screenSize` and then drawn at `scale`, so a screen laid out
/// at an iPhone's real size (393 × 852) wraps text exactly like the device does while
/// still fitting next to a form.
struct PhoneFrame<Screen: View>: View {

    var screenSize = CGSize(width: 300, height: 650)
    var scale: CGFloat = 1
    @ViewBuilder let screen: Screen

    private static var screenCornerRadius: CGFloat { 48 }
    private static var bezelWidth: CGFloat { 11 }

    var body: some View {
        screen
            .frame(width: screenSize.width, height: screenSize.height)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: screenSize.width * scale, height: screenSize.height * scale, alignment: .topLeading)
            .overlay(alignment: .top) {
                Capsule()
                    .fill(.black)
                    .frame(width: 94, height: 28)
                    .padding(.top, 11)
            }
            .clipShape(RoundedRectangle(cornerRadius: Self.screenCornerRadius, style: .continuous))
            .padding(Self.bezelWidth)
            .background {
                RoundedRectangle(cornerRadius: Self.screenCornerRadius + Self.bezelWidth, style: .continuous)
                    .fill(.black)
            }
            .overlay {
                // Titanium band around the bezel.
                RoundedRectangle(cornerRadius: Self.screenCornerRadius + Self.bezelWidth, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color(white: 0.78), Color(white: 0.45), Color(white: 0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
            }
            .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
    }
}
