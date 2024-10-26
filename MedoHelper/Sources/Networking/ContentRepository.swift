//
//  ContentRepository.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 25/10/24.
//

import Foundation

protocol ContentRepositoryProtocol {

    func create(content: MedoContent) async throws -> CreateContentResponse?

    func update(content: MedoContent) async throws
}

final class ContentRepository: ContentRepositoryProtocol {

    private let apiClient: APIClient

    init(
        apiClient: APIClient = APIClient()
    ) {
        self.apiClient = apiClient
    }

    func create(content: MedoContent) async throws -> CreateContentResponse? {
        let url = URL(string: serverPath + "v3/create-sound/\(assetOperationPassword)")!
        return try await apiClient.post(data: content, to: url)
    }

    func update(content: MedoContent) async throws {
        let url = URL(string: serverPath + "v3/update-content/\(assetOperationPassword)")!
        let _ = try await apiClient.put(in: url, data: content)
    }
}
