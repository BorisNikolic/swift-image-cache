
//  ImageDownloading.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import UIKit

/// Abstraction for downloading images from a remote URL.
///
/// Conforming types handle the network layer, allowing the `ImageLoader`
/// to remain decoupled from `URLSession` specifics (Dependency Inversion Principle).
public protocol ImageDownloading: Sendable {
    /// Downloads an image from the specified URL.
    /// - Parameter url: The remote image URL.
    /// - Returns: The downloaded `UIImage`.
    /// - Throws: `ImageLoadingError` if the download or decoding fails.
    func download(from url: URL) async throws -> UIImage
}
