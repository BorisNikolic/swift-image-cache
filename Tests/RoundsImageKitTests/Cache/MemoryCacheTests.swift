//
//  MemoryCacheTests.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

@testable import RoundsImageKit
import Testing
import UIKit

@Suite("MemoryCache")
struct MemoryCacheTests {
    let cache = MemoryCache()

    @Test func test_storeAndRetrieve() async {
        // Given
        let url = URL(string: "https://example.com/image.png")!
        let image = TestHelpers.createTestImage()

        // When
        await cache.store(image, for: url)
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
        let image = TestHelpers.createTestImage()
        await cache.store(image, for: url)

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
        let image = TestHelpers.createTestImage()
        await cache.store(image, for: url1)
        await cache.store(image, for: url2)

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
        let redImage = TestHelpers.createTestImage(color: .red)
        let blueImage = TestHelpers.createTestImage(color: .blue)

        // When
        await cache.store(redImage, for: url1)
        await cache.store(blueImage, for: url2)

        // Then
        let retrieved1 = await cache.image(for: url1)
        let retrieved2 = await cache.image(for: url2)
        #expect(retrieved1 != nil)
        #expect(retrieved2 != nil)
        #expect(retrieved1 !== retrieved2)
    }
}
