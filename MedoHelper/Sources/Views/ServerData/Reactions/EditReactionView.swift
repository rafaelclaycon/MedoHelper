//
//  EditReactionView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 01/05/24.
//

import SwiftUI

struct EditReactionView: View {

    @Binding var isBeingShown: Bool
    @State var reaction: Reaction
    private let isEditing: Bool

    init(
        isBeingShown: Binding<Bool>,
        reaction: Reaction? = nil
    ) {
        _isBeingShown = isBeingShown
        self.isEditing = reaction != nil
        self._reaction = State(initialValue: reaction ?? .init(position: 0, title: ""))
    }

    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    EditReactionView(isBeingShown: .constant(true))
}
