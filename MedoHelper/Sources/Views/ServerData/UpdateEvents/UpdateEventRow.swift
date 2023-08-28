//
//  UpdateEventRow.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 27/08/23.
//

import SwiftUI

struct UpdateEventRow: View {

    let update: UpdateEvent

    var symbol: String {
        switch update.mediaType {
        case .sound:
            return "speaker.wave.3.fill"
        case .author:
            return "person.fill"
        case .song:
            return "music.quarternote.3"
        }
    }

    var mediaText: String {
        switch update.mediaType {
        case .sound:
            return "SOM"
        case .author:
            return "AUTOR"
        case .song:
            return "MÚSICA"
        }
    }

    var eventTypeText: String {
        switch update.eventType {
        case .created:
            return "CRIADO"
        case .metadataUpdated:
            return "METADADOS ALTERADOS"
        case .fileUpdated:
            return "ARQUIVO ATUALIZADO"
        case .deleted:
            return "OCULTADO"
        }
    }

    var body: some View {
        HStack(spacing: .zero) {
            Image(systemName: symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 30)
                .foregroundColor(.orange)
                .padding(.leading)

            Spacer()
                .frame(width: 14)

            VStack(alignment: .leading, spacing: 5) {
                Text(update.contentId)
                    .multilineTextAlignment(.leading)

                Text("\(mediaText) · \(eventTypeText)")
                    .foregroundColor(.gray)
                    .font(.callout)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 5)
        .overlay(alignment: .topTrailing) {
            Text(update.dateTime.formattedDate)
                .foregroundColor(.gray)
                .font(.callout)
                .padding()
        }
        .background(.background)
        .cornerRadius(13)
        .shadow(radius: 4, y: 3)
    }
}

struct UpdateEventRow_Previews: PreviewProvider {

    static var previews: some View {
        UpdateEventRow(update: UpdateEvent(
            contentId: "9035FEFD-1205-4C55-BA4C-D825B66B0346",
            dateTime: "2023-08-24T04:47:10.337Z",
            mediaType: .author,
            eventType: .created
        ))
    }
}
