import SwiftUI

struct ContentView: View {
    
    @State var author = Author(name: "", successMessage: "...")
    @State var sound = Sound(title: "", description: "", filename: "", dateAdded: Date(), isOffensive: false, successMessage: "...")

    var body: some View {
        VStack {
            AuthorView()

            Divider()
            
            SoundView()
        }
        .frame(minWidth: 500, minHeight: 600)
    }

}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        ContentView()
    }

}
