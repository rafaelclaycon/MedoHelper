//
//  MedoHelperApp.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 24/05/22.
//

import SwiftUI

// MARK: - Server Configuration

public let baseURL: String = CommandLine.arguments.contains("-USE_LOCAL_SERVER") ? "http://127.0.0.1:8080/" : "http://medodelirioios.com:8080/"
public let serverPath: String = CommandLine.arguments.contains("-USE_LOCAL_SERVER") ? "http://127.0.0.1:8080/api/" : "http://medodelirioios.com:8080/api/"

// Note: API passwords are now stored in Secrets.xcconfig and accessed via the Secrets enum.
// See MedoHelper/Configuration/Secrets.xcconfig.template for setup instructions.

@main
struct MedoHelperApp: App {

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
