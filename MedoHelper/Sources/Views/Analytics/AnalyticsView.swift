//
//  AnalyticsView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 23/05/23.
//

import SwiftUI

struct AnalyticsView: View {
    
    var body: some View {
        VStack {
            HStack {
                Text("Estatísticas do App")
                    .font(.title)
                    .bold()
                
                Spacer()
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            //fetchSounds()
        }
    }
}

struct AnalyticsView_Previews: PreviewProvider {
    
    static var previews: some View {
        AnalyticsView()
    }
}
