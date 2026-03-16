//
//  MockImageCache.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

@testable import RoundsImageKit
import UIKit

final class MockMemoryCache: MemoryImageCaching, @unchecked Sendable {
    var storedImages: [URL: UIImage] = [:]
    private(set) var storeCallCount = 0
    private(set) var imageForCallCount = 0
    private(set) var removeCallCount = 0
    private(set) var clearAllCallCount = 0

    func cachedImage(for url: URL) -> UIImage? {
        storedImages[url]
    }

    func image(for url: URL) async -> UIImage? {
        imageForCallCount += 1
        return storedImages[url]
    }

    func store(_ image: UIImage, for url: URL) async {
        storeCallCount += 1
        storedImages[url] = image
    }

    func remove(for url: URL) async {
        removeCallCount += 1
        storedImages[url] = nil
    }

    func clearAll() async {
        clearAllCallCount += 1
        storedImages.removeAll()
    }
}

final class MockDiskCache: DiskImageCaching, @unchecked Sendable {
    var storedData: [URL: Data] = [:]
    private(set) var storeCallCount = 0
    private(set) var imageForCallCount = 0
    private(set) var removeCallCount = 0
    private(set) var clearAllCallCount = 0

    func image(for url: URL) async -> UIImage? {
        imageForCallCount += 1
        guard let data = storedData[url] else { return nil }
        return UIImage(data: data)
    }

    func store(_ data: Data, for url: URL) async {
        storeCallCount += 1
        storedData[url] = data
    }

    func remove(for url: URL) async {
        removeCallCount += 1
        storedData[url] = nil
    }

    func clearAll() async {
        clearAllCallCount += 1
        storedData.removeAll()
    }
}
