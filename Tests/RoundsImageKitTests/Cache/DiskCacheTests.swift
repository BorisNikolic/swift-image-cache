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
}
