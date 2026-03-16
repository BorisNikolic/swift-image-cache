//
//  ImageItem.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import Foundation

struct ImageItem: Codable, Identifiable, Sendable {
    let id: Int
    let imageUrl: String

    var url: URL? { URL(string: imageUrl) }
}

// Explicit nonisolated conformances required because the project uses
// SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor. Without these, synthesized
// Hashable/Equatable are main-actor-isolated and can't satisfy the
// Sendable requirement of UICollectionViewDiffableDataSource.
nonisolated extension ImageItem: Hashable, Equatable {
    static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        lhs.id == rhs.id && lhs.imageUrl == rhs.imageUrl
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(imageUrl)
    }
}
