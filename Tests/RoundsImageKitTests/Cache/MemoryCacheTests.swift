
//  MemoryCacheTests.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import Testing
import UIKit
@testable import RoundsImageKit

@Suite("MemoryCache")
struct MemoryCacheTests {
    let cache = MemoryCache()

    @Test func test_storeAndRetrieve() async {
        // Given
        let url = URL(string: "https://example.com/image.png")!
        let data = TestHelpers.createTestImageData()

        // When
        await cache.store(data, for: url)
        let retrieved = await cache.image(for: url)

        // Then
        #expect(retrieved != nil)
    }

    @Test func test_returnsNilForMissingURL() async {
        // Given
        let url = URL(string: "https://example.com/missing.png")!

        // When
        let result = await cache.image(for: url)

        // Then
        #expect(result == nil)
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
    }

    @Test func test_differentURLsStoredIndependently() async {
        // Given
        let url1 = URL(string: "https://example.com/red.png")!
        let url2 = URL(string: "https://example.com/blue.png")!
        let redData = TestHelpers.createTestImageData(color: .red)
        let blueData = TestHelpers.createTestImageData(color: .blue)

        // When
        await cache.store(redData, for: url1)
        await cache.store(blueData, for: url2)

        // Then
        let retrieved1 = await cache.image(for: url1)
        let retrieved2 = await cache.image(for: url2)
        #expect(retrieved1 != nil)
        #expect(retrieved2 != nil)
        #expect(retrieved1 !== retrieved2)
    }
}
