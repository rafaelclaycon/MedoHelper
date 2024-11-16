//
//  ReactionsCRUDViewModelTests.swift
//  MedoHelperTests
//
//  Created by Rafael Schmitt on 23/10/24.
//

import XCTest
@testable import MedoHelper

class ReactionsCRUDViewModelTests: XCTestCase {

    private var viewModel: ReactionsCRUDView.ViewModel!

    private var repository: ReactionRepositoryMock!

    @MainActor
    override func setUpWithError() throws {
        repository = ReactionRepositoryMock()
        viewModel = ReactionsCRUDView.ViewModel(reactionRepository: repository)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        repository = nil
        try super.tearDownWithError()
    }

    @MainActor
    func testOnViewAppear_whenNoReactions_shouldMakeSendButtonDisabled() async throws {
        // Given that I've opened the Reactions tab
        await viewModel.onViewAppear()

        // And there are no Reactions in the server yet
        // Then I see that the tab is empty
        XCTAssertTrue(viewModel.reactions.isEmpty)
        
        // And the `Send Data` button is disabled
        XCTAssertTrue(viewModel.isSendDataButtonDisabled)
    }

    @MainActor
    func testSendData_whenDefaultReactionsAreImportedAndSent_shouldHaveDataOnTheServer() async throws {
        // Given that I've opened the Reactions tab
        await viewModel.onViewAppear()

        // When I tap `Import From File`
        await viewModel.onImportAndSendPreExistingReactionsSelected()

        // Then all pre-existing Reactions are sent to the server
        XCTAssertTrue(repository.didCallRemoveAllReactions)
        XCTAssertTrue(repository.didCallSaveReactions)

        // And I see the populated list
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isSending)
        XCTAssertEqual(viewModel.reactions.count, 23)
    }

    @MainActor
    func testSendData_whenReorderingReactions_shouldReturnCorrectOrderFromServer() async throws {
        // Given that I've opened the Reactions tab
        await viewModel.onViewAppear()

        // And there is already some data in it
        await viewModel.onImportAndSendPreExistingReactionsSelected()
        XCTAssertTrue(repository.didCallAllReactions)

        // When I reorder one of the Reactions
        viewModel.selectedItem = "42D32EDA-9059-4CA8-A0F9-E07FFBBD41D3" // Position 1 in pre-defined data
        viewModel.onMoveReactionDownSelected()
        viewModel.onMoveReactionDownSelected()
        viewModel.onMoveReactionDownSelected()

        // Then I see that the `Send Data` button becomes enabled
        XCTAssertFalse(viewModel.isSendDataButtonDisabled)

        // When I tap the `Send Data` button
        await viewModel.onSendDataSelected()

        // Then I see that the data is sent
        // And the list is reloaded with the correct order
        XCTAssertTrue(repository.didCallRemoveAllReactions)
        XCTAssertTrue(repository.didCallSaveReactions)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.isSendDataButtonDisabled)
        XCTAssertEqual(viewModel.reactions.first?.title, "clássicos")
        XCTAssertEqual(viewModel.reactions[3].title, "deboche")
    }
}
