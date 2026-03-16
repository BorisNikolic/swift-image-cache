
//  ImageItem.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import Foundation

nonisolated struct ImageItem: Codable, Identifiable, Sendable, Hashable {
    let id: Int
    let imageUrl: String

    var url: URL? { URL(string: imageUrl) }
}
