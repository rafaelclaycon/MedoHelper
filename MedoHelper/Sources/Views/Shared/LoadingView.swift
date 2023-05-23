//
//  LoadingView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 23/05/23.
//

import SwiftUI

struct LoadingView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    var body: some View {
        ZStack {
            backgroundColor
//            RoundedRectangle(cornerRadius: 10)
//                .foregroundColor(Color.white)
//                .background(Material.regularMaterial)
//                .edgesIgnoringSafeArea(.all)
            
            HStack(spacing: 10) {
                ProgressView()
                    .scaleEffect(0.7)
                
                Text("Carregando...")
            }
            .padding()
        }
        .background(
            Material.regularMaterial
        )
        .frame(width: 160, height: 70)
    }
}

struct LoadingView_Previews: PreviewProvider {
    
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            LoadingView()
                .preferredColorScheme($0)
        }
        .previewLayout(.fixed(width: 375, height: 400))
    }
}
