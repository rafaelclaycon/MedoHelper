import SwiftUI

struct AuthorView: View {

    @Binding var authorId: String
    
    @State var author = ProtoAuthor()
    @State var createNewAuthor: Bool = false
    @State var existingAuthorUUID = ""
    
    var body: some View {
        TabView {
            VStack(spacing: 15) {
                TextField("UUID de um autor que já existe", text: $existingAuthorUUID)

                Button("Colocar UUID no som") {
                    authorId = existingAuthorUUID
                }
            }
            .padding()
            .tabItem {
                Text("Autor Existente")
            }

            VStack(spacing: 15) {
                TextField("Nome", text: $author.name)

                TextField("Descrição", text: $author.description)

                Button("Copiar JSON do Autor") {
                    authorId = UUID().uuidString

                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(generateJSONForNewAuthor(withId: authorId), forType: .string)
                    author.successMessage = "JSON de '\(author.name)' copiado!"
                }
            }
            .padding()
            .tabItem {
                Text("Novo Autor")
            }
        }
    }
    
    func generateJSONForNewAuthor(withId authorId: String) -> String {
        var authorDescription = ""
        if !author.description.isEmpty {
            authorDescription = ",\n\t\"description\": \"\(author.description)\""
        }

        return ",\n{\n\t\"id\": \"\(authorId)\",\n\t\"name\": \"\(author.name)\"\(authorDescription)\n}"
    }
}

struct AuthorView_Previews: PreviewProvider {
    
    static var previews: some View {
        AuthorView(authorId: .constant(""))
    }
}
