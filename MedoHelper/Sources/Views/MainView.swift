import SwiftUI

struct MainView: View {
    
    @State private var currentTab = 2
    @State var author = ProtoAuthor(name: "", successMessage: "...")
    @State var sound = ProtoSound(title: "", description: "", filename: "", dateAdded: Date(), isOffensive: false, successMessage: "...")
    
    var body: some View {
        NavigationView {
            List(selection: $currentTab) {
                NavigationLink {
                    AuthorView(author: $author)
                    SoundView(sound: $sound)
                } label: {
                    Text("Criação de Autor e Som")
                }
                .tag(0)

                NavigationLink {
                    ParseSoundRankingCSVView()
                } label: {
                    Text("Parse de CSV")
                }
                .tag(1)
                
                NavigationLink {
                    ManageFromServerView()
                } label: {
                    Text("Gerenciar Sons no Servidor")
                }
                .tag(2)
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
