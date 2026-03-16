//
//  DiskCache.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import CryptoKit
import UIKit

/// Persistent disk-based image cache with configurable TTL.
///
/// Stores raw image data bytes directly — no re-encoding.
/// This preserves the original format (PNG, JPEG, WebP, etc.)
/// Preserves the original format without any conversion.
/// Default TTL is 4 hours — images older than this are treated as expired.
public final class DiskCache: DiskImageCaching, @unchecked Sendable {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    private let ttl: TimeInterval
    private let sizeLimit: Int

    /// Creates a disk cache.
    /// - Parameters:
    ///   - directory: Custom cache directory name. Defaults to `"RoundsImageKit"`.
    ///   - ttl: Time-to-live in seconds. Defaults to 4 hours (14400 seconds).
    ///   - sizeLimit: Maximum total bytes on disk. Defaults to 100 MB. Oldest entries evicted first.
    public init(directory: String = "RoundsImageKit", ttl: TimeInterval = 4 * 60 * 60, sizeLimit: Int = 100 * 1024 * 1024) {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent(directory)
        self.ttl = ttl
        self.sizeLimit = sizeLimit
        createDirectoryIfNeeded()
    }

    init(cacheDirectory: URL, ttl: TimeInterval = 4 * 60 * 60, sizeLimit: Int = 100 * 1024 * 1024) {
        self.cacheDirectory = cacheDirectory
        self.ttl = ttl
        self.sizeLimit = sizeLimit
        createDirectoryIfNeeded()
    }

    public func image(for url: URL) async -> UIImage? {
        let key = cacheKey(for: url)
        let imagePath = imagePath(for: key)
        let metaPath = metaPath(for: key)

        guard fileManager.fileExists(atPath: imagePath.path) else { return nil }

        guard let metaData = try? Data(contentsOf: metaPath),
              let entry = try? JSONDecoder().decode(CacheEntry.self, from: metaData) else {
            // Missing or corrupt metadata — purge the orphaned image
            await remove(for: url)
            return nil
        }

        guard entry.isValid(ttl: ttl) else {
            await remove(for: url)
            return nil
        }

        guard let data = try? Data(contentsOf: imagePath) else { return nil }
        return UIImage(data: data)
    }

    public func store(_ data: Data, for url: URL) async {
        let key = cacheKey(for: url)
        let imagePath = imagePath(for: key)
        let metaPath = metaPath(for: key)

        do {
            try data.write(to: imagePath, options: .atomic)
            let entry = CacheEntry(
                url: url.absoluteString,
                timestamp: Date(),
                fileSize: Int64(data.count)
            )
            let metaData = try JSONEncoder().encode(entry)
            try metaData.write(to: metaPath, options: .atomic)
            evictIfNeeded()
        } catch {
            // Cache write failures are non-critical
        }
    }

    public func remove(for url: URL) async {
        let key = cacheKey(for: url)
        try? fileManager.removeItem(at: imagePath(for: key))
        try? fileManager.removeItem(at: metaPath(for: key))
    }

    public func clearAll() async {
        try? fileManager.removeItem(at: cacheDirectory)
        createDirectoryIfNeeded()
    }

    // MARK: - Private

    private func cacheKey(for url: URL) -> String {
        cacheKey(for: url.absoluteString)
    }

    private func imagePath(for key: String) -> URL {
        cacheDirectory.appendingPathComponent(key)
    }

    private func metaPath(for key: String) -> URL {
        cacheDirectory.appendingPathComponent(key + ".meta")
    }

    private func evictIfNeeded() {
        guard let metaFiles = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        ).filter({ $0.pathExtension == "meta" }) else { return }

        var entries: [EvictionCandidate] = []
        var totalSize: Int64 = 0

        for metaPath in metaFiles {
            guard let data = try? Data(contentsOf: metaPath),
                  let entry = try? JSONDecoder().decode(CacheEntry.self, from: data) else { continue }
            entries.append(EvictionCandidate(entry: entry, metaPath: metaPath))
            totalSize += entry.fileSize
        }

        guard totalSize > sizeLimit else { return }

        entries.sort { $0.entry.timestamp < $1.entry.timestamp }

        for candidate in entries {
            guard totalSize > sizeLimit else { break }
            let key = cacheKey(for: candidate.entry.url)
            try? fileManager.removeItem(at: imagePath(for: key))
            try? fileManager.removeItem(at: candidate.metaPath)
            totalSize -= candidate.entry.fileSize
        }
    }

    private struct EvictionCandidate {
        let entry: CacheEntry
        let metaPath: URL
    }

    private func cacheKey(for urlString: String) -> String {
        let digest = SHA256.hash(data: Data(urlString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
}
