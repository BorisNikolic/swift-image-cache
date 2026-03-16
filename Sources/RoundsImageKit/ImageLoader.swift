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

        /// Maximum dimension (width or height) for thumbnails stored in memory.
        /// Images larger than this are downsampled before memory caching.
        /// Defaults to 1024 (suitable for most screen sizes).
        public var maxThumbnailDimension: CGFloat

        /// Default configuration: 4h TTL, 100 images, 200 MB memory, 100 MB disk.
        public static let `default` = Configuration()

        public init(
            ttl: TimeInterval = 4 * 60 * 60,
            memoryCacheCountLimit: Int = 100,
            memoryCacheSizeLimit: Int = 200 * 1024 * 1024,
            diskCacheSizeLimit: Int = 100 * 1024 * 1024,
            maxThumbnailDimension: CGFloat = 1024
        ) {
            self.ttl = ttl
            self.memoryCacheCountLimit = memoryCacheCountLimit
            self.memoryCacheSizeLimit = memoryCacheSizeLimit
            self.diskCacheSizeLimit = diskCacheSizeLimit
            self.maxThumbnailDimension = maxThumbnailDimension
        }
    }

    // MARK: - Properties

    /// Shared singleton instance with default configuration.
    public static let shared = ImageLoader()

    private let memoryCache: MemoryImageCaching
    private let diskCache: DiskImageCaching
    private let downloader: ImageDownloading
    private let maxThumbnailDimension: CGFloat

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
        maxThumbnailDimension = configuration.maxThumbnailDimension
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
        maxThumbnailDimension = 1024
    }

    // MARK: - Public

    /// Synchronous memory cache lookup — no actor hop, no async overhead.
    /// Use this in SwiftUI `body` to instantly show cached images when
    /// `LazyVGrid` recreates a cell. Returns nil on cache miss.
    public nonisolated func cachedImage(for url: URL) -> UIImage? {
        memoryCache.cachedImage(for: url)
    }

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

        // 2. Check disk cache — downscale before promoting to memory
        if let cached = await diskCache.image(for: url) {
            let thumbnail = downsample(cached)
            await memoryCache.store(thumbnail, for: url)
            return thumbnail
        }

        // 3. Download from network
        let (image, data) = try await downloader.download(from: url)

        // 4. Store downscaled in memory, original bytes on disk
        let thumbnail = downsample(image)
        await memoryCache.store(thumbnail, for: url)
        await diskCache.store(data, for: url)

        return thumbnail
    }

    // MARK: - Private

    private func downsample(_ image: UIImage) -> UIImage {
        let imageMax = max(image.size.width, image.size.height)
        guard imageMax > maxThumbnailDimension else { return image }
        let targetSize = CGSize(width: maxThumbnailDimension, height: maxThumbnailDimension)
        return image.preparingThumbnail(of: targetSize) ?? image
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
