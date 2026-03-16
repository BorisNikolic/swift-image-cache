//
//  MockImageListService.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import Foundation

final class MockImageListService: ImageListFetching, @unchecked Sendable {
    func fetchImages() async throws -> [ImageItem] {
        [
            ImageItem(id: 0, imageUrl: "https://via.placeholder.com/300/FF0000"),
            ImageItem(id: 1, imageUrl: "https://via.placeholder.com/300/00FF00"),
            ImageItem(id: 2, imageUrl: "https://via.placeholder.com/300/0000FF")
        ]
    }
}
