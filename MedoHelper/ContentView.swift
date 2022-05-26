import SwiftUI

struct ContentView: View {
    
    @State var author = Author(name: "", successMessage: "...")
    @State var sound = Sound(title: "", description: "", filename: "", dateAdded: Date(), isOffensive: false, successMessage: "...")

    var body: some View {
        VStack {
            Text("Gerador de JSONs para o app Medo e Delírio em Brasília (iOS)")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .padding()
            
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
        }
        .frame(minWidth: 500, minHeight: 620)
    }

}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        ContentView()
    }

}
