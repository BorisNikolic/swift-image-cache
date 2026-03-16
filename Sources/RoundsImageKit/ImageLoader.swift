
//  ImageLoader.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import UIKit

/// Main public API for loading, caching, and managing images.
///
/// `ImageLoader` coordinates between memory cache, disk cache, and network
/// downloader to provide a seamless image loading experience.
///
/// ## Usage
/// ```swift
/// let image = try await ImageLoader.shared.image(for: url)
/// ```
///
/// ## Architecture
/// - **Memory cache**: Fast, in-process lookup via `NSCache`
/// - **Disk cache**: Persistent storage with configurable TTL (default 4h)
/// - **Network**: URLSession-based with request deduplication
/// - **Flow**: Memory → Disk → Network → Store in both caches
public actor ImageLoader {
    /// Shared singleton instance with default configuration.
    public static let shared = ImageLoader()

    private let memoryCache: ImageCaching
    private let diskCache: ImageCaching
    private let downloader: ImageDownloading

    /// Creates an ImageLoader with injectable dependencies.
    ///
    /// - Parameters:
    ///   - memoryCache: In-memory cache implementation. Defaults to `MemoryCache`.
    ///   - diskCache: Persistent disk cache implementation. Defaults to `DiskCache`.
    ///   - downloader: Network downloader implementation. Defaults to `ImageDownloader`.
    public init(
        memoryCache: ImageCaching = MemoryCache(),
        diskCache: ImageCaching = DiskCache(),
        downloader: ImageDownloading = ImageDownloader()
    ) {
        self.memoryCache = memoryCache
        self.diskCache = diskCache
        self.downloader = downloader
    }

    /// Loads an image from cache or network.
    ///
    /// Checks memory cache first, then disk cache, and finally downloads from the network.
    /// Successfully loaded images are stored in both caches for future access.
    ///
    /// - Parameter url: The image URL to load.
    /// - Returns: The loaded `UIImage`.
    /// - Throws: `ImageLoadingError` if all sources fail.
    public func image(for url: URL) async throws -> UIImage {
        // 1. Check memory cache
        if let cached = await memoryCache.image(for: url) {
            return cached
        }

        // 2. Check disk cache
        if let cached = await diskCache.image(for: url) {
            await memoryCache.store(cached, for: url)
            return cached
        }

        // 3. Download from network
        let image = try await downloader.download(from: url)

        // 4. Store in both caches
        await memoryCache.store(image, for: url)
        await diskCache.store(image, for: url)

        return image
    }

    /// Clears all cached images from both memory and disk.
    public func clearCache() async {
        await memoryCache.clearAll()
        await diskCache.clearAll()
    }

    /// Removes a specific image from all caches.
    /// - Parameter url: The URL of the image to remove.
    public func removeCachedImage(for url: URL) async {
        await memoryCache.remove(for: url)
        await diskCache.remove(for: url)
    }
}
