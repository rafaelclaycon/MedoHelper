//
//  UpdateEventListView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 27/08/23.
//

import SwiftUI

struct UpdateEventListView: View {

    @State private var updates: [UpdateEvent] = []

    var body: some View {
        ScrollView {
            ForEach(updates) { update in
                UpdateEventRow(update: update)
                    .padding(.vertical, 2)
            }
            .padding()
        }
        .onAppear {
            loadUpdates()
        }
    }

    private func loadUpdates() {
        Task {
            do {
                let url = URL(string: serverPath + "v3/update-events/all")!
                var fetchedUpdates: [UpdateEvent] = try await APIClient().getArray(from: url)
                fetchedUpdates.sort(by: { $0.dateTime > $1.dateTime })
                self.updates = fetchedUpdates
            } catch {
                print(error)
            }
        }
    }
}

struct UpdateEventListView_Previews: PreviewProvider {

    static var previews: some View {
        UpdateEventListView()
    }
}
