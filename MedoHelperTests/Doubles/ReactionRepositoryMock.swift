//
//  ReactionRepositoryMock.swift
//  MedoHelperTests
//
//  Created by Rafael Schmitt on 25/10/24.
//

import Foundation
@testable import MedoHelper

final class ReactionRepositoryMock: ReactionRepositoryProtocol {

    var reactions = [HelperReaction]()

    var didCallAllReactions: Bool = false
    var didCallRemoveAllReactions: Bool = false
    var didCallSaveReactions: Bool = false

    func allReactions() async throws -> [HelperReaction] {
        didCallAllReactions = true
        return reactions
    }
    
    func removeAllReactions() async throws {
        didCallRemoveAllReactions = true
    }
    
    func save(reactions: [HelperReaction], onItemDidSend: () -> Void) async throws {
        didCallSaveReactions = true
    }

    func add(reaction: HelperReaction) async throws {
        reactions.append(reaction)
    }

    func add(sounds: [ServerReactionSoundForSending]) async throws {
    }

    func reactionSoundsWithAllData(
        _ basicSounds: [ServerReactionSound],
        _ fullyFormedSounds: [Sound]
    ) async throws -> [ReactionSoundForDisplay] {
        return []
    }

    func update(reaction: HelperReaction) async throws {
    }

    func removeAllSoundsOf(reactionId: String) async throws {
    }

    func removeReaction(withId reactionId: String) async throws {
    }
}
