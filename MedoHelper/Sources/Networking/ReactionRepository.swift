//
//  ReactionRepository.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 24/10/24.
//

import Foundation

protocol ReactionRepositoryProtocol {

    func allReactions() async throws -> [ReactionDTO]

    func removeAllReactions() async throws

    func save(
        reactions: [ReactionDTO],
        onItemDidSend: () -> Void
    ) async throws
}

final class ReactionRepository: ReactionRepositoryProtocol {

    private let apiClient: APIClient

    init(
        apiClient: APIClient = APIClient()
    ) {
        self.apiClient = apiClient
    }

    func allReactions() async throws -> [ReactionDTO] {
        let url = URL(string: serverPath + "v4/reactions")!

        let serverReactions: [AppReaction] = try await apiClient.getArray(from: url)
        var dtos = serverReactions.map { ReactionDTO(appReaction: $0) }
        dtos.sort(by: { $0.position < $1.position })

        guard !dtos.isEmpty else { return [] }

        for i in 0...(dtos.count - 1) {
            let reactionUrl = URL(string: serverPath + "v4/reaction/\(dtos[i].id)")!
            dtos[i].sounds = try await apiClient.getArray(from: reactionUrl)
        }

        return dtos
    }

    func removeAllReactions() async throws {
        let reactionsUrl = URL(string: serverPath + "v4/delete-all-reactions/\(reactionsPassword)")!
        let soundsUrl = URL(string: serverPath + "v4/delete-all-reaction-sounds/\(reactionsPassword)")!
        guard try await apiClient.delete(in: reactionsUrl) else {
            throw ReactionRepositoryError.errorDeletingReactions
        }
        guard try await apiClient.delete(in: soundsUrl) else {
            throw ReactionRepositoryError.errorDeletingReactionSounds
        }
    }

    func save(
        reactions: [ReactionDTO],
        onItemDidSend: () -> Void
    ) async throws {
        for reaction in reactions {
            try await send(reaction: AppReaction(dto: reaction))

            if let sounds = reaction.sounds {
                let dtos = sounds.map { ReactionSoundDTO(reactionSound: $0, reactionId: reaction.id) }
                try await send(reactionSounds: dtos)
            }

            onItemDidSend()
        }
    }
}

// MARK: - Internal Functions

extension ReactionRepository {

    private func send(reaction: AppReaction) async throws {
        let url = URL(string: serverPath + "v4/create-reaction/\(reactionsPassword)")!
        let _ = try await apiClient.post(data: reaction, to: url)
    }

    private func send(reactionSounds: [ReactionSoundDTO]) async throws {
        let url = URL(string: serverPath + "v4/add-sounds-to-reaction/\(reactionsPassword)")!
        let _ = try await apiClient.post(data: reactionSounds, to: url)
    }
}

// MARK: - Errors

public enum ReactionRepositoryError: Error {

    case errorDeletingReactions
    case errorDeletingReactionSounds
}
