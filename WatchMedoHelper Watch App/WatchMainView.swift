//
//  WatchMainView.swift
//  WatchMedoHelper Watch App
//
//  Created by Rafael Schmitt on 10/02/25.
//

import SwiftUI

struct WatchMainView: View {

    @State private var serverState: ServerState = .loading

    var body: some View {
        VStack {
            switch serverState {
            case .loading:
                VStack(spacing: 15) {
                    ProgressView()

                    Text("CARREGANDO...")
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                }

            case .operational:
                VStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title)

                    Text("Tudo certo com o servidor.")
                        .bold()
                        .multilineTextAlignment(.center)
                }

            case .hasIssues:
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.title)

                    Text("Problemas.")
                        .bold()
                        .multilineTextAlignment(.center)
                }

            case .couldNotReach:
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .font(.title)

                    Text("Não foi possível determinar o status do servidor.")
                        .bold()
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .onAppear {
            Task {
                serverState = .loading
                await checkServer()
            }
        }
    }

    private func checkServer() async {
        do {
            let url = URL(string: "http://170.187.145.233:8080/api/v2/status-check/")!

            let statusCode: Int = try await APIClient().getStatusCode(from: url)

            if (200...299).contains(statusCode) {
                self.serverState = .operational
            } else {
                self.serverState = .hasIssues
            }
        } catch {
            print(error)
            self.serverState = .couldNotReach
        }
    }
}

#Preview {
    WatchMainView()
}
