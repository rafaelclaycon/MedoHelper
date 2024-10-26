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

    func allReactions() async throws -> [MedoHelper.HelperReaction] {
        didCallAllReactions = true
        return reactions
    }
    
    func removeAllReactions() async throws {
        didCallRemoveAllReactions = true
    }
    
    func save(reactions: [MedoHelper.HelperReaction], onItemDidSend: () -> Void) async throws {
        didCallSaveReactions = true
    }
}
