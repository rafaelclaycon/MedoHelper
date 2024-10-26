//
//  SendingProgressView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 04/05/23.
//

import SwiftUI

struct SendingProgressView: View {

    let message: String
    let currentAmount: Double
    let totalAmount: Double

    var body: some View {
        VStack {
            ProgressView(message, value: currentAmount, total: totalAmount)
        }
        .frame(width: 300, height: 140)
        .padding(.horizontal, 50)
    }
}

#Preview {
    SendingProgressView(
        message: "Enviando Som...",
        currentAmount: 1,
        totalAmount: 2
    )
}
