//
//  DiskCache.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import CryptoKit
import UIKit

/// Persistent disk-based image cache with configurable TTL and size limit.
///
/// Stores raw image data bytes directly — no re-encoding.
/// Preserves the original format (PNG, JPEG, WebP) without any conversion.
///
/// Uses a Nuke-inspired sweep strategy:
/// - Tracks `currentSize` in memory (cheap integer comparison on every store)
/// - Periodic background sweep on init (delayed, low priority)
/// - When over limit, trims to `trimRatio` (70%) to avoid sweeping again immediately
/// - Sweep removes expired entries first, then oldest by timestamp
public final class DiskCache: DiskImageCaching, @unchecked Sendable {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    private let ttl: TimeInterval
    private let sizeLimit: Int
    private let trimRatio: Double = 0.7
    private let sweepDelay: TimeInterval = 5
    private var currentSize: Int64 = 0
    private let ioQueue = DispatchQueue(label: "com.roundsimagekit.diskcache", qos: .utility)

    /// Creates a disk cache.
    /// - Parameters:
    ///   - directory: Custom cache directory name. Defaults to `"RoundsImageKit"`.
    ///   - ttl: Time-to-live in seconds. Defaults to 4 hours.
    ///   - sizeLimit: Maximum total bytes on disk. Defaults to 100 MB.
    public init(
        directory: String = "RoundsImageKit",
        ttl: TimeInterval = 4 * 60 * 60,
        sizeLimit: Int = 100 * 1024 * 1024
    ) {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent(directory)
        self.ttl = ttl
        self.sizeLimit = sizeLimit
        createDirectoryIfNeeded()
        calculateCurrentSize()
        scheduleSweep()
    }

    init(
        cacheDirectory: URL,
        ttl: TimeInterval = 4 * 60 * 60,
        sizeLimit: Int = 100 * 1024 * 1024
    ) {
        self.cacheDirectory = cacheDirectory
        self.ttl = ttl
        self.sizeLimit = sizeLimit
        createDirectoryIfNeeded()
        calculateCurrentSize()
    }

    // MARK: - DiskImageCaching

    public func image(for url: URL) async -> UIImage? {
        let key = cacheKey(for: url)
        let imagePath = imagePath(for: key)
        let metaPath = metaPath(for: key)

        guard fileManager.fileExists(atPath: imagePath.path) else { return nil }

        guard let metaData = try? Data(contentsOf: metaPath),
              let entry = try? JSONDecoder().decode(CacheEntry.self, from: metaData) else {
            await remove(for: url)
            return nil
        }

        guard entry.isValid(ttl: ttl) else {
            currentSize -= entry.fileSize
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

        // Remove old entry size if overwriting
        if let existingMeta = try? Data(contentsOf: metaPath),
           let existing = try? JSONDecoder().decode(CacheEntry.self, from: existingMeta) {
            currentSize -= existing.fileSize
        }

        do {
            try data.write(to: imagePath, options: .atomic)
            let entry = CacheEntry(
                url: url.absoluteString,
                timestamp: Date(),
                fileSize: Int64(data.count)
            )
            let metaData = try JSONEncoder().encode(entry)
            try metaData.write(to: metaPath, options: .atomic)
            currentSize += Int64(data.count)
        } catch {
            return
        }

        // Cheap integer check — no filesystem scan
        if currentSize > sizeLimit {
            performSweep()
        }
    }

    public func remove(for url: URL) async {
        let key = cacheKey(for: url)
        try? fileManager.removeItem(at: imagePath(for: key))
        try? fileManager.removeItem(at: metaPath(for: key))
    }

    public func clearAll() async {
        try? fileManager.removeItem(at: cacheDirectory)
        currentSize = 0
        createDirectoryIfNeeded()
    }

    // MARK: - Sweep

    private func scheduleSweep() {
        ioQueue.asyncAfter(deadline: .now() + sweepDelay) { [weak self] in
            self?.performSweep()
        }
    }

    private func performSweep() {
        guard let metaFiles = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        ).filter({ $0.pathExtension == "meta" }) else { return }

        var entries: [EvictionCandidate] = []
        var totalSize: Int64 = 0

        for metaPath in metaFiles {
            guard let data = try? Data(contentsOf: metaPath),
                  let entry = try? JSONDecoder().decode(CacheEntry.self, from: data) else {
                // Corrupt meta — remove orphan
                let imageName = metaPath.deletingPathExtension().lastPathComponent
                try? fileManager.removeItem(at: imagePath(for: imageName))
                try? fileManager.removeItem(at: metaPath)
                continue
            }

            // Remove expired entries immediately
            if !entry.isValid(ttl: ttl) {
                let key = cacheKey(for: entry.url)
                try? fileManager.removeItem(at: imagePath(for: key))
                try? fileManager.removeItem(at: metaPath)
                continue
            }

            entries.append(EvictionCandidate(entry: entry, metaPath: metaPath))
            totalSize += entry.fileSize
        }

        // Trim to trimRatio (70%) of limit to avoid sweeping again immediately
        let targetSize = Int64(Double(sizeLimit) * trimRatio)
        guard totalSize > sizeLimit else {
            currentSize = totalSize
            return
        }

        // Sort oldest first
        entries.sort { $0.entry.timestamp < $1.entry.timestamp }

        for candidate in entries {
            guard totalSize > targetSize else { break }
            let key = cacheKey(for: candidate.entry.url)
            try? fileManager.removeItem(at: imagePath(for: key))
            try? fileManager.removeItem(at: candidate.metaPath)
            totalSize -= candidate.entry.fileSize
        }

        currentSize = totalSize
    }

    // MARK: - Private

    private func calculateCurrentSize() {
        guard let metaFiles = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        ).filter({ $0.pathExtension == "meta" }) else { return }

        var total: Int64 = 0
        for metaPath in metaFiles {
            if let data = try? Data(contentsOf: metaPath),
               let entry = try? JSONDecoder().decode(CacheEntry.self, from: data) {
                total += entry.fileSize
            }
        }
        currentSize = total
    }

    private func cacheKey(for url: URL) -> String {
        cacheKey(for: url.absoluteString)
    }

    private func cacheKey(for urlString: String) -> String {
        let digest = SHA256.hash(data: Data(urlString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func imagePath(for key: String) -> URL {
        cacheDirectory.appendingPathComponent(key)
    }

    private func metaPath(for key: String) -> URL {
        cacheDirectory.appendingPathComponent(key + ".meta")
    }

    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    private struct EvictionCandidate {
        let entry: CacheEntry
        let metaPath: URL
    }
}
