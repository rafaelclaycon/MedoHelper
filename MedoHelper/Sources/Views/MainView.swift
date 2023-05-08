import SwiftUI

struct MainView: View {
    
    @State private var currentTab = 2
    @State var author = ProtoAuthor(name: "", successMessage: "...")
    @State var sound = ProtoSound(title: "", description: "", filename: "", dateAdded: Date(), isOffensive: false, successMessage: "...")
    
    var body: some View {
        NavigationView {
            List(selection: $currentTab) {
                Section("LOCAL") {
                    NavigationLink {
                        AuthorView(author: $author)
                        SoundView(sound: $sound)
                    } label: {
                        Label("Criar Autor e Som", systemImage: "plus.circle")
                    }
                    .tag(0)
                    
                    NavigationLink {
                        ParseSoundRankingCSVView()
                    } label: {
                        Label("Parsear CSV", systemImage: "text.justify.leading")
                    }
                    .tag(1)
                }
                
                Section("REMOTO") {
                    NavigationLink {
                        SoundsOuterView()
                    } label: {
                        Label("Sons", systemImage: "speaker.wave.3")
                    }
                    .tag(2)
                    
                    NavigationLink {
                        AuthorsOuterView()
                    } label: {
                        Label("Autores", systemImage: "person.2")
                    }
                    .tag(3)
                    
                    NavigationLink {
                        MoveAuthorsToServerView()
                    } label: {
                        Label("Músicas", systemImage: "music.quarternote.3")
                    }
                    .tag(4)
                }
            }
            .listStyle(.sidebar)
            
//                HStack(spacing: 15) {
//                    Spacer()
//                    Button("Limpar Tudo") {
//                        author = ProtoAuthor(name: "", successMessage: "...")
//                        sound = ProtoSound(title: "", description: "", filename: "", dateAdded: Date(), isOffensive: false, successMessage: "...")
//                    }
//                    Button("Limpar Apenas Som") {
//                        sound = ProtoSound(title: "", description: "", filename: "", dateAdded: Date(), isOffensive: false, successMessage: "...")
//                    }
//                }
//                .padding(.trailing, 15)
        }
    }
}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        MainView()
    }

}
