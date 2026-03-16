
//  ImageListService.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import Foundation

protocol ImageListFetching: Sendable {
    func fetchImages() async throws -> [ImageItem]
}

final class ImageListService: ImageListFetching, @unchecked Sendable {
    private let session: URLSession
    private let endpoint = URL(string: "https://zipoapps-storage-test.nyc3.digitaloceanspaces.com/image_list.json")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchImages() async throws -> [ImageItem] {
        let (data, response) = try await session.data(from: endpoint)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([ImageItem].self, from: data)
    }
}
