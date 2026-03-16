//
//  DiskCacheTests.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

@testable import RoundsImageKit
import Testing
import UIKit

@Suite("DiskCache")
struct DiskCacheTests {
    let tempDirectory: URL
    let cache: DiskCache

    init() {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DiskCacheTests-\(UUID().uuidString)")
        cache = DiskCache(cacheDirectory: tempDirectory, ttl: 3600)
    }

    @Test func test_storeAndRetrieve() async {
        // Given
        let url = URL(string: "https://example.com/image.png")!
        let data = TestHelpers.createTestImageData()

        // When
        await cache.store(data, for: url)
        let retrieved = await cache.image(for: url)

        // Then
        #expect(retrieved != nil)

        // Cleanup
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    @Test func test_returnsNilForMissingURL() async {
        // Given
        let url = URL(string: "https://example.com/missing.png")!

        // When
        let result = await cache.image(for: url)

        // Then
        #expect(result == nil)

        // Cleanup
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    @Test func test_removeSpecificImage() async {
        // Given
        let url = URL(string: "https://example.com/image.png")!
        let data = TestHelpers.createTestImageData()
        await cache.store(data, for: url)

        // When
        await cache.remove(for: url)
        let result = await cache.image(for: url)

        // Then
        #expect(result == nil)

        // Cleanup
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    @Test func test_clearAllRemovesEverything() async {
        // Given
        let url1 = URL(string: "https://example.com/1.png")!
        let url2 = URL(string: "https://example.com/2.png")!
        let data = TestHelpers.createTestImageData()
        await cache.store(data, for: url1)
        await cache.store(data, for: url2)

        // When
        await cache.clearAll()

        // Then
        #expect(await cache.image(for: url1) == nil)
        #expect(await cache.image(for: url2) == nil)

        // Cleanup
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    @Test func test_expiredImageReturnsNil() async {
        // Given — TTL of 0 means everything expires immediately
        let expiredCache = DiskCache(cacheDirectory: tempDirectory, ttl: 0)
        let url = URL(string: "https://example.com/expired.png")!
        let data = TestHelpers.createTestImageData()

        // When
        await expiredCache.store(data, for: url)
        let result = await expiredCache.image(for: url)

        // Then
        #expect(result == nil)

        // Cleanup
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    @Test func test_validImageWithinTTL() async {
        // Given — TTL of 3600 seconds
        let longLivedCache = DiskCache(cacheDirectory: tempDirectory, ttl: 3600)
        let url = URL(string: "https://example.com/valid.png")!
        let data = TestHelpers.createTestImageData()

        // When
        await longLivedCache.store(data, for: url)
        let result = await longLivedCache.image(for: url)

        // Then
        #expect(result != nil)

        // Cleanup
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    @Test func test_evictsOldestWhenSizeLimitExceeded() async {
        // Given — limit = 2 images. After storing 3, sweep trims to 70% (1.4 images).
        // Oldest entries are removed first, so 2 oldest go, 1 newest survives.
        let evictDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DiskCacheEvict-\(UUID().uuidString)")
        let data = TestHelpers.createTestImageData()
        let limit = data.count * 2
        let evictCache = DiskCache(cacheDirectory: evictDir, ttl: 3600, sizeLimit: limit)

        let url1 = URL(string: "https://example.com/first.png")!
        let url2 = URL(string: "https://example.com/second.png")!
        let url3 = URL(string: "https://example.com/third.png")!

        // When — store 3 images, exceeding the 2-image limit
        await evictCache.store(data, for: url1)
        await evictCache.store(data, for: url2)
        await evictCache.store(data, for: url3)

        // Then — oldest (url1) should be evicted, newest (url3) should survive
        let first = await evictCache.image(for: url1)
        let third = await evictCache.image(for: url3)
        #expect(first == nil)
        #expect(third != nil)

        // Cleanup
        try? FileManager.default.removeItem(at: evictDir)
    }

    @Test func test_sweepRemovesExpiredEntries() async {
        // Given — TTL of 0 means everything expires, sweep should clean them
        let sweepDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DiskCacheSweep-\(UUID().uuidString)")
        let expiredCache = DiskCache(cacheDirectory: sweepDir, ttl: 0, sizeLimit: 100 * 1024 * 1024)
        let data = TestHelpers.createTestImageData()
        let url = URL(string: "https://example.com/sweep.png")!

        // When — store then immediately read (TTL=0 means expired)
        await expiredCache.store(data, for: url)
        let result = await expiredCache.image(for: url)

        // Then
        #expect(result == nil)

        // Cleanup
        try? FileManager.default.removeItem(at: sweepDir)
    }
}
