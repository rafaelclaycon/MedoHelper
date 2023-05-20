import SwiftUI

struct MainView: View {
    
    @State private var currentTab = 0
    
    var body: some View {
        NavigationView {
            List(selection: $currentTab) {
                Section("REMOTO") {
                    NavigationLink {
                        ServerSoundsCRUDView()
                    } label: {
                        Label("Sons", systemImage: "speaker.wave.3")
                    }
                    .tag(0)
                    
                    NavigationLink {
                        ServerAuthorsCRUDView()
                    } label: {
                        Label("Autores", systemImage: "person.2")
                    }
                    .tag(1)
                    
                    NavigationLink {
                        ServerSoundsCRUDView()
                    } label: {
                        Label("Músicas", systemImage: "music.quarternote.3")
                    }
                    .tag(2)
                }
                
                Section("LOCAL") {
                    NavigationLink {
                        CreateAuthorAndSoundView()
                    } label: {
                        Label("Criar Autor e Som", systemImage: "plus.circle")
                    }
                    .tag(3)
                    
                    NavigationLink {
                        ParseSoundRankingCSVView()
                    } label: {
                        Label("Parsear CSV", systemImage: "text.justify.leading")
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
