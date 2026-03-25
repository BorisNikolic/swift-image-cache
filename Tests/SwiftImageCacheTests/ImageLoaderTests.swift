//
//  ImageLoaderTests.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

@testable import SwiftImageCache
import Testing
import UIKit

@Suite("ImageLoader")
struct ImageLoaderTests {
    let memoryCache = MockMemoryCache()
    let diskCache = MockDiskCache()
    let downloader = MockImageDownloader()

    var loader: ImageLoader {
        ImageLoader(memoryCache: memoryCache, diskCache: diskCache, downloader: downloader)
    }

    @Test func test_loadFromNetwork_whenCacheEmpty() async throws {
        // Given
        let url = URL(string: "https://example.com/image.png")!
        let testImage = TestHelpers.createTestImage()
        let testData = TestHelpers.createTestImageData()
        downloader.resultToReturn = .success((testImage, testData))

        // When
        let result = try await loader.image(for: url)

        // Then
        #expect(result != nil)
        #expect(downloader.downloadCallCount == 1)
        #expect(downloader.downloadedURLs == [url])
        #expect(memoryCache.storeCallCount == 1)
        #expect(diskCache.storeCallCount == 1)
    }

    @Test func test_loadFromMemoryCache_whenAvailable() async throws {
        // Given
        let url = URL(string: "https://example.com/cached.png")!
        let testImage = TestHelpers.createTestImage()
        memoryCache.storedImages[url] = testImage

        // When
        let result = try await loader.image(for: url)

        // Then
        #expect(result != nil)
        #expect(downloader.downloadCallCount == 0)
        #expect(diskCache.imageForCallCount == 0)
    }

    @Test func test_loadFromDiskCache_whenMemoryEmpty() async throws {
        // Given
        let url = URL(string: "https://example.com/disk.png")!
        let testData = TestHelpers.createTestImageData()
        diskCache.storedData[url] = testData

        // When
        let result = try await loader.image(for: url)

        // Then
        #expect(result != nil)
        #expect(downloader.downloadCallCount == 0)
        #expect(memoryCache.storeCallCount == 1)
    }

    @Test func test_clearCache_removesAllImages() async {
        // Given
        let url = URL(string: "https://example.com/image.png")!
        let testImage = TestHelpers.createTestImage()
        let testData = TestHelpers.createTestImageData()
        memoryCache.storedImages[url] = testImage
        diskCache.storedData[url] = testData

        // When
        await loader.clearCache()

        // Then
        #expect(memoryCache.clearAllCallCount == 1)
        #expect(diskCache.clearAllCallCount == 1)
    }

    @Test func test_removeCachedImage_removesSpecific() async {
        // Given
        let url = URL(string: "https://example.com/remove.png")!
        let testImage = TestHelpers.createTestImage()
        let testData = TestHelpers.createTestImageData()
        memoryCache.storedImages[url] = testImage
        diskCache.storedData[url] = testData

        // When
        await loader.removeCachedImage(for: url)

        // Then
        #expect(memoryCache.removeCallCount == 1)
        #expect(diskCache.removeCallCount == 1)
        #expect(memoryCache.storedImages[url] == nil)
        #expect(diskCache.storedData[url] == nil)
    }
}
