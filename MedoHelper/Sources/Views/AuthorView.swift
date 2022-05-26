import SwiftUI

struct AuthorView: View {

    @Binding var author: Author
    @State var createNewAuthor: Bool = false
    @State var existingAuthorUUID = ""
    
    var body: some View {
        VStack {
            Toggle("Criar novo autor", isOn: $createNewAuthor)
            
            TextField("Nome do Novo Autor", text: $author.name)
                .disabled(createNewAuthor == false)
                .padding()
            
            TextField("UUID de um autor que já existe", text: $existingAuthorUUID)
                .disabled(createNewAuthor == true)
                .padding()

            Button(createNewAuthor ? "Copiar JSON Autor" : "Colocar UUID na var autor") {
                if createNewAuthor {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(generateJSONForNewAuthor(), forType: .string)
                    author.successMessage = "JSON de '\(author.name)' copiado!"
                } else {
                    authorId = existingAuthorUUID
                    author.successMessage = "UUID '\(authorId)' colocado na var autor!"
                }
            }

            Text(author.successMessage)
                .padding()
        }
    }
    
    func generateJSONForNewAuthor() -> String {
        authorId = UUID().uuidString
        return ",\n{\n\t\"id\": \"\(authorId)\",\n\t\"name\": \"\(author.name)\"\n}"
    }

}

struct AuthorView_Previews: PreviewProvider {

    static var previews: some View {
        AuthorView(author: .constant(Author(name: "", successMessage: "...")))
    }

}
