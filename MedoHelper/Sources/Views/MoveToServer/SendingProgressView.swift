//
//  SendingProgressView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 04/05/23.
//

import SwiftUI

struct SendingProgressView: View {
    
    @Binding var isBeingShown: Bool
    @Binding var message: String
    @Binding var currentAmount: Double
    @State var totalAmount: Double
    
    var body: some View {
        VStack {
            ProgressView(message, value: currentAmount, total: totalAmount)
        }
        .frame(width: 300, height: 140)
        .padding(.horizontal, 50)
    }
}

struct SendingProgressView_Previews: PreviewProvider {
    
    static var previews: some View {
        SendingProgressView(isBeingShown: .constant(true), message: .constant("Enviando Som..."), currentAmount: .constant(1), totalAmount: 2)
    }
}
