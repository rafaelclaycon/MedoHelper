//
//  DynamicBannerData.swift
//  MedoHelper
//
//  Created by Claude on 25/10/26.
//

import Foundation

/// The banner the app shows on Vírgulas, stored on the server as this JSON. Mirrors
/// `DynamicBannerData` in the app, which decodes it as is: renaming a field here breaks
/// the banner for everyone.
struct DynamicBannerData: Codable, Equatable {

    /// An SF Symbol name.
    let symbol: String
    let title: String
    /// Paragraphs shown when the banner is expanded. Markdown, so `**bold**` works.
    let text: [String]
    let buttons: [DynamicBannerButton]
}

struct DynamicBannerButton: Codable, Equatable {

    let title: String
    let type: DynamicBannerButtonType
    /// The text copied, or the link opened.
    let data: String
    /// For `copyText`, the toast shown after copying.
    let additionalData: String?
}

enum DynamicBannerButtonType: String, Codable, CaseIterable, Identifiable {

    case copyText, openLink

    var id: String { rawValue }

    var name: String {
        switch self {
        case .copyText: return "Copiar texto"
        case .openLink: return "Abrir link"
        }
    }
}
