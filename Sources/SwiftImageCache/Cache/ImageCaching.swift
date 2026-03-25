//
//  ImageCaching.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import UIKit

/// Abstraction for in-memory image caching.
///
/// Stores decoded `UIImage` instances directly for zero-cost retrieval.
public protocol MemoryImageCaching: Sendable {
    /// Synchronous retrieval for instant display (e.g. SwiftUI body).
    /// Safe because NSCache is thread-safe.
    func cachedImage(for url: URL) -> UIImage?

    /// Retrieves a cached image for the given URL, if available.
    func image(for url: URL) async -> UIImage?

    /// Stores a decoded image in the cache for the given URL.
    func store(_ image: UIImage, for url: URL) async

    /// Removes a cached image for the given URL.
    func remove(for url: URL) async

    /// Clears all cached images.
    func clearAll() async
}

/// Abstraction for persistent disk-based image caching.
///
/// Stores raw `Data` bytes to preserve the original image format (PNG, JPEG, etc.)
/// without re-encoding.
public protocol DiskImageCaching: Sendable {
    /// Retrieves a cached image for the given URL, if available.
    func image(for url: URL) async -> UIImage?

    /// Stores raw image data in the cache for the given URL.
    func store(_ data: Data, for url: URL) async

    /// Removes a cached image for the given URL.
    func remove(for url: URL) async

    /// Clears all cached images.
    func clearAll() async
}
