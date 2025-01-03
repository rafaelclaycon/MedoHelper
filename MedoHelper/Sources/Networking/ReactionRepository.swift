//
//  ReactionRepository.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 24/10/24.
//

import Foundation

protocol ReactionRepositoryProtocol {

    // Create

    func add(reaction: HelperReaction) async throws

    func save(
        reactions: [HelperReaction],
        onItemDidSend: () -> Void
    ) async throws

    /// Adds Reaction sounds.
    /// Reaction ID is set on each sound, so no need to pass here.
    func add(sounds: [ServerReactionSoundForSending]) async throws

    // Read

    func allReactions() async throws -> [HelperReaction]

    /// Used to display Sound title and Author name on Reaction detail.
    func reactionSoundsWithAllData(
        _ basicSounds: [ServerReactionSound],
        _ fullyFormedSounds: [Sound]
    ) async throws -> [ReactionSoundForDisplay]

    // Update

    func update(reaction: HelperReaction) async throws

    // Delete

    func removeAllReactions() async throws
    func removeAllSoundsOf(reactionId: String) async throws
    func removeReaction(withId reactionId: String) async throws
}

final class ReactionRepository: ReactionRepositoryProtocol {

    private let apiClient: APIClient

    // MARK: - Initializer

    init(
        apiClient: APIClient = APIClient()
    ) {
        self.apiClient = apiClient
    }
}

// MARK: - Create

extension ReactionRepository {

    func add(reaction: HelperReaction) async throws {
        try await send(reaction: ServerReaction(helperReaction: reaction))
    }

    func save(
        reactions: [HelperReaction],
        onItemDidSend: () -> Void
    ) async throws {
        for reaction in reactions {
            try await send(reaction: ServerReaction(helperReaction: reaction))

            if let sounds = reaction.sounds {
                let dtos = sounds.map { ServerReactionSoundForSending(reactionSound: $0, reactionId: reaction.id) }
                try await send(reactionSounds: dtos)
            }

            onItemDidSend()
        }
    }

    func add(sounds: [ServerReactionSoundForSending]) async throws {
        let url = URL(string: serverPath + "v4/add-sounds-to-reaction/\(reactionsPassword)")!
        let _ = try await apiClient.post(data: sounds, to: url)
    }
}

// MARK: - Read

extension ReactionRepository {

    func allReactions() async throws -> [HelperReaction] {
        let url = URL(string: serverPath + "v4/reactions")!

        let serverReactions: [ServerReaction] = try await apiClient.getArray(from: url)
        var dtos = serverReactions.map { HelperReaction(serverReaction: $0) }
        dtos.sort(by: { $0.position < $1.position })

        guard !dtos.isEmpty else { return [] }

        for i in 0...(dtos.count - 1) {
            let reactionUrl = URL(string: serverPath + "v4/reaction-sounds/\(dtos[i].id)")!
            dtos[i].sounds = try await apiClient.get(from: reactionUrl)
        }

        return dtos
    }

    func reactionSoundsWithAllData(
        _ basicSounds: [ServerReactionSound],
        _ fullyFormedSounds: [Sound]
    ) async throws -> [ReactionSoundForDisplay] {
        var sounds: [ReactionSoundForDisplay] = []

        basicSounds.forEach { basicSound in
            guard let fullSound = fullyFormedSounds.first(where: { $0.id == basicSound.soundId }) else { return }

            sounds.append(
                .init(
                    id: basicSound.id,
                    soundId: basicSound.soundId,
                    title: fullSound.title,
                    authorName: fullSound.authorName ?? "",
                    dateAdded: basicSound.dateAdded,
                    position: basicSound.position
                )
            )
        }

        return sounds
    }
}

// MARK: - Update

extension ReactionRepository {

    func update(reaction: HelperReaction) async throws {
        let updateUrl = URL(string: serverPath + "v4/reaction/\(reactionsPassword)")!
        let _ = try await apiClient.put(in: updateUrl, data: reaction)
    }
}

// MARK: - Delete

extension ReactionRepository {

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

    func removeAllSoundsOf(reactionId: String) async throws {
        let url = URL(string: serverPath + "v4/delete-reaction-sounds/\(reactionId)/\(reactionsPassword)")!
        let _ = try await apiClient.delete(in: url)
    }

    func removeReaction(withId reactionId: String) async throws {
        try await removeAllSoundsOf(reactionId: reactionId)
        let url = URL(string: serverPath + "v4/delete-reaction/\(reactionId)/\(reactionsPassword)")!
        let _ = try await apiClient.delete(in: url)
    }
}

// MARK: - Internal Functions

extension ReactionRepository {

    private func send(reaction: ServerReaction) async throws {
        let url = URL(string: serverPath + "v4/create-reaction/\(reactionsPassword)")!
        let _ = try await apiClient.post(data: reaction, to: url)
    }

    private func send(reactionSounds: [ServerReactionSoundForSending]) async throws {
        let url = URL(string: serverPath + "v4/add-sounds-to-reaction/\(reactionsPassword)")!
        let _ = try await apiClient.post(data: reactionSounds, to: url)
    }
}

// MARK: - Errors

public enum ReactionRepositoryError: Error {

    case errorDeletingReactions
    case errorDeletingReactionSounds
}
