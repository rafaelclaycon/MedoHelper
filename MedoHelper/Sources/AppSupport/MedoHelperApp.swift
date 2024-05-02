//
//  MedoHelperApp.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 24/05/22.
//

import SwiftUI

public let baseURL: String = CommandLine.arguments.contains("-USE_LOCAL_SERVER") ? "http://127.0.0.1:8080/" : "http://medodelirioios.online:8080/"
public let serverPath: String = CommandLine.arguments.contains("-USE_LOCAL_SERVER") ? "http://127.0.0.1:8080/api/" : "http://medodelirioios.online:8080/api/"
public let assetOperationPassword = "reckless-frontage-solve-unmoor"

@main
struct MedoHelperApp: App {

    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 500, minHeight: 500)
        }
        //.windowStyle(HiddenTitleBarWindowStyle())
    }
}
