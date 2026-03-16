//
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
/// // Default configuration
/// let image = try await ImageLoader.shared.image(for: url)
///
/// // Custom configuration
/// let loader = ImageLoader(configuration: .init(ttl: 2 * 60 * 60, memoryCacheCountLimit: 50))
/// let image = try await loader.image(for: url)
/// ```
///
/// ## Architecture
/// - **Memory cache**: Fast, in-process lookup via `NSCache`
/// - **Disk cache**: Persistent storage with configurable TTL (default 4h)
/// - **Network**: URLSession-based with request deduplication
/// - **Flow**: Memory → Disk → Network → Store original bytes in both caches
public actor ImageLoader {

    // MARK: - Configuration

    /// Configuration for controlling cache behavior.
    public struct Configuration: Sendable {
        /// Time-to-live for disk-cached images in seconds. Defaults to 4 hours.
        public var ttl: TimeInterval

        /// Maximum number of images to keep in memory cache.
        public var memoryCacheCountLimit: Int

        /// Maximum total bytes for the memory cache. Defaults to 50 MB.
        public var memoryCacheSizeLimit: Int

        /// Maximum total bytes for the disk cache. Defaults to 100 MB.
        /// When exceeded, oldest entries are evicted first.
        public var diskCacheSizeLimit: Int

        /// Default configuration: 4h TTL, 100 images, 50 MB memory, 100 MB disk.
        public static let `default` = Configuration()

        public init(
            ttl: TimeInterval = 4 * 60 * 60,
            memoryCacheCountLimit: Int = 100,
            memoryCacheSizeLimit: Int = 50 * 1024 * 1024,
            diskCacheSizeLimit: Int = 100 * 1024 * 1024
        ) {
            self.ttl = ttl
            self.memoryCacheCountLimit = memoryCacheCountLimit
            self.memoryCacheSizeLimit = memoryCacheSizeLimit
            self.diskCacheSizeLimit = diskCacheSizeLimit
        }
    }

    // MARK: - Properties

    /// Shared singleton instance with default configuration.
    public static let shared = ImageLoader()

    private let memoryCache: MemoryImageCaching
    private let diskCache: DiskImageCaching
    private let downloader: ImageDownloading

    // MARK: - Init

    /// Creates an ImageLoader from a configuration.
    ///
    /// - Parameter configuration: Cache and TTL settings. Defaults to `.default`.
    public init(configuration: Configuration = .default) {
        memoryCache = MemoryCache(
            countLimit: configuration.memoryCacheCountLimit,
            totalCostLimit: configuration.memoryCacheSizeLimit
        )
        diskCache = DiskCache(ttl: configuration.ttl, sizeLimit: configuration.diskCacheSizeLimit)
        downloader = ImageDownloader()
    }

    /// Creates an ImageLoader with injectable dependencies for testing.
    ///
    /// - Parameters:
    ///   - memoryCache: In-memory cache implementation.
    ///   - diskCache: Persistent disk cache implementation.
    ///   - downloader: Network downloader implementation.
    public init(
        memoryCache: MemoryImageCaching,
        diskCache: DiskImageCaching,
        downloader: ImageDownloading
    ) {
        self.memoryCache = memoryCache
        self.diskCache = diskCache
        self.downloader = downloader
    }

    // MARK: - Public

    /// Loads an image from cache or network.
    ///
    /// Checks memory cache first, then disk cache, and finally downloads from the network.
    /// Disk hits are promoted to memory cache directly as `UIImage` — no re-encoding.
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
        let (image, data) = try await downloader.download(from: url)

        // 4. Store in both caches
        await memoryCache.store(image, for: url)
        await diskCache.store(data, for: url)

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
