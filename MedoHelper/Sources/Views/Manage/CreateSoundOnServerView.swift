//
//  CreateSoundOnServerView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 30/04/23.
//

import SwiftUI

struct CreateSoundOnServerView: View {
    
    @Binding var sound: ProtoSound
    
    var body: some View {
        VStack {
            TextField("Título do Som", text: $sound.title)
                .padding()
            
            TextField("Descrição do Som", text: $sound.description)
                .padding()
            
            HStack {
                Text("")
                
                Button("Selecionar arquivo...") {
                    print("Escolher pressionado")
                }
            }
            .padding()
            
            HStack(spacing: 50) {
                DatePicker("Data de adição", selection: $sound.dateAdded, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(width: 110)
                
                Toggle("É ofensivo", isOn: $sound.isOffensive)
            }
            .padding()
            
            HStack {
                Spacer()
                
                Button {
                    post(content: MedoContent(title: "O aí ó", authorId: "abcd", description: "o ai o", contentFileId: "fdfdfdfdf.mp3", creationDate: "2023-04-27T00:00:00Z", duration: 2.24, isOffensive: true)) { result, error in
                        if result {
                            print("Sucesso")
                        } else {
                            print("Problema")
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "paperplane")
                        Text("Enviar")
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)

            Text(sound.successMessage)
                .padding()
        }
    }
    
    func post(content: MedoContent, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: "http://127.0.0.1:8080/api/v3/create-sound")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonEncoder = JSONEncoder()
        let jsonData = try? jsonEncoder.encode(content)
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                return
            }
             
            guard httpResponse.statusCode == 200 else {
                return completion(false, "Failed")
            }
            
            guard error == nil else {
                return completion(false, "HTTP Request Failed \(error!.localizedDescription)")
            }
            
            completion(true, "")
        }

        task.resume()
    }
}

struct CreateSoundOnServerView_Previews: PreviewProvider {
    
    static var previews: some View {
        CreateSoundOnServerView(sound: .constant(ProtoSound(title: "", description: "", filename: "", dateAdded: Date(), isOffensive: false, successMessage: "...")))
    }
}
