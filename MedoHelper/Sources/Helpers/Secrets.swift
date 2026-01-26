//
//  Secrets.swift
//  MedoHelper
//
//  Created by Cursor on 26/01/26.
//

import Foundation

/// Provides access to API secrets stored in Info.plist via xcconfig
enum Secrets {

    static let assetOperationPassword: String = {
        guard let value = Bundle.main.infoDictionary?["AssetOperationPassword"] as? String,
              !value.isEmpty,
              !value.hasPrefix("$(") else {
            fatalError("Missing AssetOperationPassword in Info.plist. Make sure Secrets.xcconfig exists and is configured.")
        }
        return value
    }()

    static let reactionsPassword: String = {
        guard let value = Bundle.main.infoDictionary?["ReactionsPassword"] as? String,
              !value.isEmpty,
              !value.hasPrefix("$(") else {
            fatalError("Missing ReactionsPassword in Info.plist. Make sure Secrets.xcconfig exists and is configured.")
        }
        return value
    }()

    static let analyticsPassword: String = {
        guard let value = Bundle.main.infoDictionary?["AnalyticsPassword"] as? String,
              !value.isEmpty,
              !value.hasPrefix("$(") else {
            fatalError("Missing AnalyticsPassword in Info.plist. Make sure Secrets.xcconfig exists and is configured.")
        }
        return value
    }()
}
