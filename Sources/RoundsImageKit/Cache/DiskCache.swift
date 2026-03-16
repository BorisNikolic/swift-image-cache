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
/// All file I/O runs on a dedicated background queue (`ioQueue`) so it never
/// blocks the ImageLoader actor or the main thread. Uses in-memory size
/// tracking with periodic background sweeps for eviction.
public final class DiskCache: DiskImageCaching, @unchecked Sendable {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    private let ttl: TimeInterval
    private let sizeLimit: Int
    private let trimRatio: Double = 0.7
    private let sweepDelay: TimeInterval = 5
    private var currentSize: Int64 = 0
    private let ioQueue = DispatchQueue(label: "com.roundsimagekit.diskcache", qos: .utility)

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
        ioQueue.sync { calculateCurrentSize() }
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
        ioQueue.sync { calculateCurrentSize() }
    }

    // MARK: - DiskImageCaching

    public func image(for url: URL) async -> UIImage? {
        let key = cacheKey(for: url)
        let imgPath = imagePath(for: key)
        let mtaPath = metaPath(for: key)

        return await withCheckedContinuation { continuation in
            ioQueue.async { [self] in
                guard fileManager.fileExists(atPath: imgPath.path) else {
                    continuation.resume(returning: nil)
                    return
                }

                guard let metaData = try? Data(contentsOf: mtaPath),
                      let entry = try? JSONDecoder().decode(CacheEntry.self, from: metaData) else {
                    try? fileManager.removeItem(at: imgPath)
                    try? fileManager.removeItem(at: mtaPath)
                    continuation.resume(returning: nil)
                    return
                }

                guard entry.isValid(ttl: ttl) else {
                    currentSize -= entry.fileSize
                    try? fileManager.removeItem(at: imgPath)
                    try? fileManager.removeItem(at: mtaPath)
                    continuation.resume(returning: nil)
                    return
                }

                guard let data = try? Data(contentsOf: imgPath) else {
                    continuation.resume(returning: nil)
                    return
                }

                let image = UIImage(data: data)
                continuation.resume(returning: image)
            }
        }
    }

    public func store(_ data: Data, for url: URL) async {
        let key = cacheKey(for: url)
        let imgPath = imagePath(for: key)
        let mtaPath = metaPath(for: key)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ioQueue.async { [self] in
                if let existingMeta = try? Data(contentsOf: mtaPath),
                   let existing = try? JSONDecoder().decode(CacheEntry.self, from: existingMeta) {
                    currentSize -= existing.fileSize
                }

                do {
                    try data.write(to: imgPath, options: .atomic)
                    let entry = CacheEntry(
                        url: url.absoluteString,
                        timestamp: Date(),
                        fileSize: Int64(data.count)
                    )
                    let metaData = try JSONEncoder().encode(entry)
                    try metaData.write(to: mtaPath, options: .atomic)
                    currentSize += Int64(data.count)
                } catch {
                    continuation.resume()
                    return
                }

                if currentSize > sizeLimit {
                    performSweep()
                }

                continuation.resume()
            }
        }
    }

    public func remove(for url: URL) async {
        let key = cacheKey(for: url)
        let imgPath = imagePath(for: key)
        let mtaPath = metaPath(for: key)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ioQueue.async { [self] in
                try? fileManager.removeItem(at: imgPath)
                try? fileManager.removeItem(at: mtaPath)
                continuation.resume()
            }
        }
    }

    public func clearAll() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ioQueue.async { [self] in
                try? fileManager.removeItem(at: cacheDirectory)
                currentSize = 0
                createDirectoryIfNeeded()
                continuation.resume()
            }
        }
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

        for path in metaFiles {
            guard let data = try? Data(contentsOf: path),
                  let entry = try? JSONDecoder().decode(CacheEntry.self, from: data) else {
                let imageName = path.deletingPathExtension().lastPathComponent
                try? fileManager.removeItem(at: imagePath(for: imageName))
                try? fileManager.removeItem(at: path)
                continue
            }

            if !entry.isValid(ttl: ttl) {
                let key = cacheKey(for: entry.url)
                try? fileManager.removeItem(at: imagePath(for: key))
                try? fileManager.removeItem(at: path)
                continue
            }

            entries.append(EvictionCandidate(entry: entry, metaPath: path))
            totalSize += entry.fileSize
        }

        let targetSize = Int64(Double(sizeLimit) * trimRatio)
        guard totalSize > sizeLimit else {
            currentSize = totalSize
            return
        }

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
        for path in metaFiles {
            if let data = try? Data(contentsOf: path),
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
