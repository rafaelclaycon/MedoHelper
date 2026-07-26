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

    func delete(contentId: String, contentType: ContentType) async throws
}

final class ContentRepository: ContentRepositoryProtocol {

    private let apiClient: APIClient

    init(
        apiClient: APIClient = APIClient()
    ) {
        self.apiClient = apiClient
    }

    func create(content: MedoContent) async throws -> CreateContentResponse? {
        let endpoint = content.contentType == .sound ? "create-sound" : "create-song"
        let url = URL(string: serverPath + "v3/\(endpoint)/\(Secrets.assetOperationPassword)")!
        return try await apiClient.post(data: content, to: url)
    }

    func update(content: MedoContent) async throws {
        let url = URL(string: serverPath + "v3/update-content/\(Secrets.assetOperationPassword)")!
        let _ = try await apiClient.put(in: url, data: content)
    }

    func delete(contentId: String, contentType: ContentType) async throws {
        let endpoint = contentType == .sound ? "sound" : "song"
        let url = URL(string: serverPath + "v3/\(endpoint)/\(contentId)/\(Secrets.assetOperationPassword)")!
        let _ = try await apiClient.delete(in: url, data: nil as String?)
    }
}
