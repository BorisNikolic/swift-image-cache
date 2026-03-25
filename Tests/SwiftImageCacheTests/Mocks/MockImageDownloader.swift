//
//  MockImageDownloader.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

@testable import SwiftImageCache
import UIKit

final class MockImageDownloader: ImageDownloading, @unchecked Sendable {
    var resultToReturn: Result<(UIImage, Data), Error> = .success((UIImage(), Data()))
    private(set) var downloadCallCount = 0
    private(set) var downloadedURLs: [URL] = []
    var delayNanoseconds: UInt64?

    func download(from url: URL) async throws -> (UIImage, Data) {
        downloadCallCount += 1
        downloadedURLs.append(url)

        if let delayNanoseconds {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }

        return try resultToReturn.get()
    }
}
