
//  MemoryCache.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import UIKit

/// In-memory image cache backed by `NSCache`.
///
/// Automatically evicts entries under memory pressure.
/// Thread-safe by design (NSCache is thread-safe).
public final class MemoryCache: ImageCaching, @unchecked Sendable {
    private let cache = NSCache<NSString, UIImage>()

    public init(countLimit: Int = 100, totalCostLimit: Int = 50 * 1024 * 1024) {
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }

    public func image(for url: URL) async -> UIImage? {
        cache.object(forKey: url.absoluteString as NSString)
    }

    public func store(_ image: UIImage, for url: URL) async {
        let cost = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        cache.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
    }

    public func remove(for url: URL) async {
        cache.removeObject(forKey: url.absoluteString as NSString)
    }

    public func clearAll() async {
        cache.removeAllObjects()
    }
}
