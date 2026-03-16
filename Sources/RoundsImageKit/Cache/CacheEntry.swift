
//  CacheEntry.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import Foundation

/// Metadata stored alongside each cached image on disk.
///
/// Tracks when the image was cached so the disk cache can enforce TTL expiration.
struct CacheEntry: Codable, Sendable {
    let url: String
    let timestamp: Date
    let fileSize: Int64

    var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }

    func isValid(ttl: TimeInterval) -> Bool {
        age < ttl
    }
}
