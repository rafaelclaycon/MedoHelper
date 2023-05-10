//
//  CreateAuthorAndSoundView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 10/05/23.
//

import SwiftUI

struct CreateAuthorAndSoundView: View {
    
    var body: some View {
        ScrollView {
            AuthorView()
            SoundView()
        }
        .padding()
    }
}

struct CreateAuthorAndSoundView_Previews: PreviewProvider {
    
    static var previews: some View {
        CreateAuthorAndSoundView()
    }
}
