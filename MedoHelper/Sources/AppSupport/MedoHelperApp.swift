import SwiftUI

public var authorId: String = ""
public let serverPath: String = CommandLine.arguments.contains("-USE_LOCAL_SERVER") ? "http://127.0.0.1:8080/api/" : "http://170.187.141.103:8080/api/"

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
