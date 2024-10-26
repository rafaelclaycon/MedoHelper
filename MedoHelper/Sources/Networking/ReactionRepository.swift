//
//  ReactionRepository.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 24/10/24.
//

import Foundation

protocol ReactionRepositoryProtocol {

    // Create

    func save(
        reactions: [ReactionDTO],
        onItemDidSend: () -> Void
    ) async throws

    /// Adds Reaction sounds.
    /// Reaction ID is set on each sound, so no need to pass here.
    func add(sounds: [ReactionSoundDTO]) async throws

    // Read

    func allReactions() async throws -> [ReactionDTO]

    /// Used to display Sound title and Author name on Reaction detail.
    func reactionSoundsWithAllData(_ basicSounds: [ReactionSound]) async throws -> [ReactionSoundForDisplay]

    // Update

    func update(reaction: ReactionDTO) async throws

    // Delete

    func removeAllReactions() async throws
    func removeAllSoundsOf(reactionId: String) async throws
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

    func add(sounds: [ReactionSoundDTO]) async throws {
        let url = URL(string: serverPath + "v4/add-sounds-to-reaction/\(reactionsPassword)")!
        let _ = try await apiClient.post(data: sounds, to: url)
    }
}

// MARK: - Read

extension ReactionRepository {

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

    func reactionSoundsWithAllData(_ basicSounds: [ReactionSound]) async throws -> [ReactionSoundForDisplay] {
        var sounds: [ReactionSoundForDisplay] = []

        for basicSound in basicSounds {
            let soundDetailUrl = URL(string: serverPath + "v3/sound/\(basicSound.soundId)")!
            let serverSound: SoundDTO = try await apiClient.get(from: soundDetailUrl)

            let auhtorDetailUrl = URL(string: serverPath + "v3/author/\(serverSound.authorId)")!
            let author: Author = try await apiClient.get(from: auhtorDetailUrl)

            sounds.append(
                .init(
                    id: basicSound.id,
                    soundId: basicSound.soundId,
                    title: serverSound.title,
                    authorName: author.name,
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

    func update(reaction: ReactionDTO) async throws {
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
