
//  ImageCaching.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import UIKit

/// Abstraction for image caching operations.
///
/// Conforming types provide storage and retrieval of images keyed by URL.
/// Both memory and disk implementations conform to this protocol,
/// enabling dependency injection and testability (Dependency Inversion Principle).
public protocol ImageCaching: Sendable {
    /// Retrieves a cached image for the given URL, if available.
    func image(for url: URL) async -> UIImage?

    /// Stores an image in the cache for the given URL.
    func store(_ image: UIImage, for url: URL) async

    /// Removes a cached image for the given URL.
    func remove(for url: URL) async

    /// Clears all cached images.
    func clearAll() async
}
