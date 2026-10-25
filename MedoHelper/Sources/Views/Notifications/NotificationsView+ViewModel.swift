//
//  NotificationsView+ViewModel.swift
//  MedoHelper
//
//  Created by Claude on 25/10/26.
//

import SwiftUI

extension NotificationsView {

    @MainActor
    final class ViewModel: ObservableObject {

        @Published var title: String = ""
        @Published var body: String = ""

        /// Devices a broadcast would reach right now. Nil while loading.
        @Published var audienceCount: Int?
        /// The broadcast sending now, or the last one sent since the server started.
        @Published var broadcast: PushBroadcastStatus?
        @Published var isStarting: Bool = false
        @Published var isCancelling: Bool = false
        @Published var showSendConfirmation: Bool = false

        @Published var alertTitle: String = ""
        @Published var alertMessage: String = ""
        @Published var showAlert: Bool = false

        private let repository: PushBroadcastRepositoryProtocol
        private var pollingTask: Task<Void, Never>?

        private static let pollingInterval: Duration = .seconds(1)

        init(repository: PushBroadcastRepositoryProtocol = PushBroadcastRepository()) {
            self.repository = repository
        }

        var isSending: Bool {
            isStarting || broadcast?.state == .sending
        }

        var canSend: Bool {
            !isSending
                && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

// MARK: - User Actions

extension NotificationsView.ViewModel {

    func onViewAppear() async {
        if Secrets.sendNotificationPassword == nil {
            showAlert(
                title: "Senha não configurada",
                message: "Adicione SEND_NOTIFICATION_PASSWORD ao Secrets.xcconfig (o mesmo valor do servidor) e rode o app de novo."
            )
            return
        }
        await loadAudience()
        do {
            // Picks a broadcast back up if it was started before the app was (re)opened.
            broadcast = try await repository.broadcasts().first
            if broadcast?.state == .sending {
                startPolling()
            }
        } catch {
            print(error)
        }
    }

    func onViewDisappear() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func onSendSelected() {
        guard canSend else { return }
        showSendConfirmation = true
    }

    func onSendConfirmed() async {
        isStarting = true
        defer { isStarting = false }
        do {
            broadcast = try await repository.send(
                PushBroadcastRequest(title: title, body: body)
            )
            startPolling()
        } catch {
            print(error)
            showAlert(title: "Não foi possível enviar", message: error.localizedDescription)
        }
    }

    func onCancelSelected() async {
        guard let id = broadcast?.id else { return }
        isCancelling = true
        defer { isCancelling = false }
        do {
            // The server stops before the next device; polling picks up the final state.
            broadcast = try await repository.cancel(id: id)
        } catch {
            print(error)
            showAlert(title: "Não foi possível cancelar", message: error.localizedDescription)
        }
    }
}

// MARK: - Internal Operations

extension NotificationsView.ViewModel {

    private func loadAudience() async {
        do {
            audienceCount = try await repository.audience()
        } catch {
            print(error)
        }
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.pollingInterval)
                guard let self, let id = self.broadcast?.id else { return }
                do {
                    let latest = try await self.repository.broadcast(id: id)
                    guard !Task.isCancelled else { return }
                    self.broadcast = latest
                    if latest.state != .sending {
                        // Invalid tokens were deleted along the way.
                        await self.loadAudience()
                        return
                    }
                } catch PushBroadcastError.server(statusCode: 404, _) {
                    // Progress lives in the server's memory, so a restart loses the broadcast.
                    self.broadcast = nil
                    self.showAlert(
                        title: "Envio interrompido",
                        message: "O servidor não conhece mais esse envio. Ele provavelmente reiniciou e parou no meio."
                    )
                    return
                } catch {
                    // A dropped request shouldn't end the progress view; try again next tick.
                    print(error)
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
