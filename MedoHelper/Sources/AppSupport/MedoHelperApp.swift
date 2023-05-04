import SwiftUI

public var authorId: String = ""
public let serverPath: String = CommandLine.arguments.contains("-UNDER_DEVELOPMENT") ? "http://127.0.0.1:8080/api/" : "http://medodelirioios.lat:8080/api/"

@main
struct MedoHelperApp: App {

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }

}
