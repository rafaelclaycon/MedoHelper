//
//  ManageFromServerView.swift
//  MedoHelper
//
//  Created by Rafael Claycon Schmitt on 30/04/23.
//

import SwiftUI

struct ManageFromServerView: View {
    
    @State private var currentTab = 1
    @State private var sound = ProtoSound(title: "", description: "", filename: "", dateAdded: Date(), isOffensive: false, successMessage: "...")
    
    var body: some View {
        VStack {
            Picker("", selection: $currentTab) {
                Text("Visualizar").tag(0)
                Text("Criar").tag(1)
            }
            .pickerStyle(.segmented)
            .frame(width: 350)
            
            if currentTab == 0 {
                Text("Viz")
            } else {
                CreateSoundOnServerView(sound: $sound)
            }
        }
    }
}

struct ManageFromServerView_Previews: PreviewProvider {
    
    static var previews: some View {
        ManageFromServerView()
    }
}
