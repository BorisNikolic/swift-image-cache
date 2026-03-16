
//  ImageCaching.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import UIKit

/// Abstraction for image caching operations.
///
/// Conforming types provide storage and retrieval of images keyed by URL.
/// Stores raw `Data` bytes to preserve the original image format (PNG, JPEG, etc.)
/// without re-encoding — following the same approach as Kingfisher, Nuke, and SDWebImage.
public protocol ImageCaching: Sendable {
    /// Retrieves a cached image for the given URL, if available.
    func image(for url: URL) async -> UIImage?

    /// Stores raw image data in the cache for the given URL.
    func store(_ data: Data, for url: URL) async

    /// Removes a cached image for the given URL.
    func remove(for url: URL) async

    /// Clears all cached images.
    func clearAll() async
}
