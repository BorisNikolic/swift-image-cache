
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
}

/// URLSession-based image downloader with request deduplication.
///
/// When multiple callers request the same URL concurrently, only one network
/// request is made. All callers await the same in-flight task.
///
/// Uses `Task.detached` so caller cancellation (e.g. a cell scrolling off-screen)
/// does not kill the shared download. The in-flight task map is only cleaned up
/// when the download itself completes — not when individual callers cancel.
public actor ImageDownloader: ImageDownloading {
    private let session: URLSession
    private var inFlightTasks: [URL: Task<(UIImage, Data), Error>] = [:]

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func download(from url: URL) async throws -> (UIImage, Data) {
        if let existingTask = inFlightTasks[url] {
            return try await existingTask.value
        }

        let capturedSession = session
        let task = Task.detached { () -> (UIImage, Data) in
            let (data, response): (Data, URLResponse)
            do {
                (data, response) = try await capturedSession.data(from: url)
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

            return (image, data)
        }

        inFlightTasks[url] = task

        // Detached so it doesn't inherit the caller's cancellation state.
        // Cleans up the map only when the download itself finishes.
        Task.detached { [weak self] in
            _ = try? await task.value
            await self?.removeInFlight(for: url)
        }

        return try await task.value
    }

    private func removeInFlight(for url: URL) {
        inFlightTasks[url] = nil
    }
}
