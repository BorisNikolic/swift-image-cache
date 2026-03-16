
//  ImageDownloaderTests.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import Testing
import UIKit
@testable import RoundsImageKit

@Suite("ImageDownloader", .serialized)
struct ImageDownloaderTests {
    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    @Test func test_successfulDownload() async throws {
        // Given
        let url = URL(string: "https://example.com/image.png")!
        let testImage = TestHelpers.createTestImage()
        let imageData = testImage.jpegData(compressionQuality: 1.0)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, imageData)
        }

        let downloader = ImageDownloader(session: makeSession())

        // When
        let result = try await downloader.download(from: url)

        // Then
        #expect(result.size.width > 0)
    }

    @Test func test_invalidImageDataThrowsError() async {
        // Given
        let url = URL(string: "https://example.com/bad.png")!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("not an image".utf8))
        }

        let downloader = ImageDownloader(session: makeSession())

        // When / Then
        await #expect(throws: ImageLoadingError.self) {
            try await downloader.download(from: url)
        }
    }

    @Test func test_networkErrorThrowsError() async {
        // Given
        let url = URL(string: "https://example.com/error.png")!

        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let downloader = ImageDownloader(session: makeSession())

        // When / Then
        await #expect(throws: ImageLoadingError.self) {
            try await downloader.download(from: url)
        }
    }

    @Test func test_invalidStatusCodeThrowsError() async {
        // Given
        let url = URL(string: "https://example.com/notfound.png")!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let downloader = ImageDownloader(session: makeSession())

        // When / Then
        await #expect(throws: ImageLoadingError.self) {
            try await downloader.download(from: url)
        }
    }
}
