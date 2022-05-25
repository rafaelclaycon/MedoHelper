import SwiftUI

struct AuthorView: View {

    @State private var authorName: String = ""
    @State private var authorNameCopied: String = "..."

    var body: some View {
        VStack {
            Text("Gerador de JSONs para o app Medo e Delírio em Brasília (iOS)")
                .font(.title)
                .bold()
                .padding()

            TextField("Nome do Autor", text: $authorName)
                .padding()

            Button("Gerar JSON Autor") {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(generateAuthorJSON(), forType: .string)
                authorNameCopied = "JSON de '\(authorName)' copiado!"
            }

            Text(authorNameCopied)
                .padding()
        }
    }
    
    func generateAuthorJSON() -> String {
        authorId = UUID().uuidString
        return ",\n{\n\t\"id\": \"\(authorId)\",\n\t\"name\": \"\(authorName)\"\n}"
    }

}

struct AuthorView_Previews: PreviewProvider {

    static var previews: some View {
        AuthorView()
    }

}
