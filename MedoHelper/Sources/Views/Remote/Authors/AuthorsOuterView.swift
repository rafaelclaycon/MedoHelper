//
//  AuthorsOuterView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 05/05/23.
//

import SwiftUI

struct AuthorsOuterView: View {
    
    @State private var currentTab = 0
    
    var body: some View {
        VStack {
            Picker("", selection: $currentTab) {
                Text("CRUD Servidor").tag(0)
                Text("Enviar Autores Já no App").tag(1)
            }
            .pickerStyle(.segmented)
            .frame(width: 350)
            
            if currentTab == 0 {
                Text("Coming")
            } else {
                MoveAuthorsToServerView()
            }
        }
    }
}

struct AuthorsOuterView_Previews: PreviewProvider {
    
    static var previews: some View {
        AuthorsOuterView()
    }
}
