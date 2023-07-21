//
//  CreateAuthorAndSoundView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 10/05/23.
//

import SwiftUI

struct CreateAuthorAndSoundView: View {

    @State private var authorId: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AuthorView(authorId: $authorId)
                SoundView(authorId: $authorId)
            }
        }
        .padding(.all, 26)
    }
}

struct CreateAuthorAndSoundView_Previews: PreviewProvider {
    
    static var previews: some View {
        CreateAuthorAndSoundView()
    }
}
