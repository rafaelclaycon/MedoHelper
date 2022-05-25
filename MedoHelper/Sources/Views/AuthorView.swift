import SwiftUI

struct AuthorView: View {

    @Binding var author: Author

    var body: some View {
        VStack {
            TextField("Nome do Autor", text: $author.name)
                .padding()

            Button("Gerar JSON Autor") {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(generateAuthorJSON(), forType: .string)
                author.successMessage = "JSON de '\(author.name)' copiado!"
            }

            Text(author.successMessage)
                .padding()
        }
    }
    
    func generateAuthorJSON() -> String {
        authorId = UUID().uuidString
        return ",\n{\n\t\"id\": \"\(authorId)\",\n\t\"name\": \"\(author.name)\"\n}"
    }

}

struct AuthorView_Previews: PreviewProvider {

    static var previews: some View {
        AuthorView(author: .constant(Author(name: "", successMessage: "...")))
    }

}
