
//  MockImageCache.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import UIKit
@testable import RoundsImageKit

final class MockImageCache: ImageCaching, @unchecked Sendable {
    var storedImages: [URL: UIImage] = [:]
    private(set) var storeCallCount = 0
    private(set) var imageForCallCount = 0
    private(set) var removeCallCount = 0
    private(set) var clearAllCallCount = 0

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
