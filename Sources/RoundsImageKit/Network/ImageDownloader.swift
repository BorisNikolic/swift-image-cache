
//  ImageDownloader.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import UIKit

/// Errors that can occur during image loading.
public enum ImageLoadingError: Error, Sendable {
    case invalidURL
    case networkError(Error)
    case invalidResponse(Int)
    case invalidImageData
    case cancelled
}

/// URLSession-based image downloader with request deduplication.
///
/// When multiple callers request the same URL concurrently, only one network
/// request is made. All callers await the same in-flight task.
public actor ImageDownloader: ImageDownloading {
    private let session: URLSession
    private var inFlightTasks: [URL: Task<UIImage, Error>] = [:]

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func download(from url: URL) async throws -> UIImage {
        if let existingTask = inFlightTasks[url] {
            return try await existingTask.value
        }

        let task = Task<UIImage, Error> {
            defer { inFlightTasks[url] = nil }

            let (data, response): (Data, URLResponse)
            do {
                (data, response) = try await session.data(from: url)
            } catch {
                throw ImageLoadingError.networkError(error)
            }

            if let httpResponse = response as? HTTPURLResponse,
               !(200 ... 299).contains(httpResponse.statusCode) {
                throw ImageLoadingError.invalidResponse(httpResponse.statusCode)
            }

            guard let image = UIImage(data: data) else {
                throw ImageLoadingError.invalidImageData
            }

            return image
        }

        inFlightTasks[url] = task
        return try await task.value
    }
}
