//
//  CachedAsyncImage.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import SwiftUI

/// A SwiftUI view that asynchronously loads and caches an image from a URL.
///
/// Displays a placeholder while the image is loading or if loading fails.
/// The placeholder receives a `Bool` indicating whether loading is in progress,
/// so it can conditionally show a spinner.
///
/// ## Usage
/// ```swift
/// CachedAsyncImage(url: imageURL) { isLoading in
///     ZStack {
///         Image(systemName: "photo")
///         if isLoading { ProgressView() }
///     }
/// }
/// ```
public struct CachedAsyncImage<Placeholder: View>: View {
    private let url: URL?
    private let imageLoader: ImageLoader
    private let makePlaceholder: (Bool) -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    /// Creates a cached async image view.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - imageLoader: The image loader to use. Defaults to `.shared`.
    ///   - placeholder: A view builder that receives `isLoading` — `true` while
    ///     the image is being fetched, `false` when loading finished (success or failure).
    public init(
        url: URL?,
        imageLoader: ImageLoader = .shared,
        @ViewBuilder placeholder: @escaping (Bool) -> Placeholder
    ) {
        self.url = url
        self.imageLoader = imageLoader
        makePlaceholder = placeholder
    }

    public var body: some View {
        GeometryReader { geometry in
            if let displayImage {
                Image(uiImage: displayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                makePlaceholder(isLoading)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .clipped()
        .task(id: url) {
            await loadImage()
        }
    }

    /// Check sync memory cache first (instant, no actor hop),
    /// then fall back to async-loaded @State image.
    private var displayImage: UIImage? {
        if let url, let cached = imageLoader.cachedImage(for: url) {
            return cached
        }
        return image
    }

    @MainActor
    private func loadImage() async {
        guard let url, !isLoading else { return }
        if image != nil { return }

        // Fast path: sync memory cache hit
        if let cached = imageLoader.cachedImage(for: url) {
            image = cached
            return
        }

        isLoading = true

        do {
            let loaded = try await imageLoader.image(for: url)
            if !Task.isCancelled {
                image = loaded
            }
        } catch {
            // On failure: placeholder stays visible
        }

        isLoading = false
    }
}

// MARK: - Convenience initializer with default placeholder

public extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    /// Creates a cached async image with a default `ProgressView` placeholder.
    init(url: URL?, imageLoader: ImageLoader = .shared) {
        self.init(url: url, imageLoader: imageLoader) { _ in
            ProgressView()
        }
    }
}
