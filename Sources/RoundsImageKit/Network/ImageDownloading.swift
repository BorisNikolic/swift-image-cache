
//  ImageDownloading.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import UIKit

/// Abstraction for downloading images from a remote URL.
///
/// Returns both the decoded `UIImage` and the raw `Data` bytes,
/// so the cache layer can store original data without re-encoding.
public protocol ImageDownloading: Sendable {
    /// Downloads an image from the specified URL.
    /// - Parameter url: The remote image URL.
    /// - Returns: A tuple of the decoded `UIImage` and the original response `Data`.
    /// - Throws: `ImageLoadingError` if the download or decoding fails.
    func download(from url: URL) async throws -> (UIImage, Data)
}
