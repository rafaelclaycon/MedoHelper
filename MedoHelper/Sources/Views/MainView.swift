import SwiftUI

struct MainView: View {

    @State private var currentTab = 0
    @State var author = Author(name: "", successMessage: "...")
    @State var sound = Sound(title: "", description: "", filename: "", dateAdded: Date(), isOffensive: false, successMessage: "...")

    var body: some View {
        VStack {
            Picker("", selection: $currentTab) {
                Text("Gerador de JSONs").tag(0)
                Text("Interpretador de ranking de compartilhamento").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if currentTab == 0 {
                HStack(spacing: 15) {
                    Spacer()
                    Button("Limpar Tudo") {
                        author = Author(name: "", successMessage: "...")
                        sound = Sound(title: "", description: "", filename: "", dateAdded: Date(), isOffensive: false, successMessage: "...")
                    }
                    Button("Limpar Apenas Som") {
                        sound = Sound(title: "", description: "", filename: "", dateAdded: Date(), isOffensive: false, successMessage: "...")
                    }
                }
                .padding(.trailing, 15)
                
                AuthorView(author: $author)

                Divider()
                
                SoundView(sound: $sound)
            } else {
                ParseSoundRankingCSVView()
                
                Spacer()
            }
        }
        .frame(minWidth: 500, minHeight: 680)
    }

}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        MainView()
    }

}
