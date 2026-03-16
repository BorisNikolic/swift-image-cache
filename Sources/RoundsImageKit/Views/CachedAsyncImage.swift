//
//  CachedAsyncImage.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import SwiftUI

/// A SwiftUI view that asynchronously loads and caches an image from a URL.
///
/// Displays a placeholder while the image is loading, then cross-fades to the
/// loaded image. Shows an error indicator if loading fails.
/// Uses `ImageLoader` for two-tier caching (memory + disk).
///
/// ## Usage
/// ```swift
/// CachedAsyncImage(url: imageURL) {
///     ProgressView()
/// }
/// ```
public struct CachedAsyncImage<Placeholder: View>: View {
    private let url: URL?
    private let imageLoader: ImageLoader
    private let placeholder: Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadError: Error?

    /// Creates a cached async image view.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - imageLoader: The image loader to use. Defaults to `.shared`.
    ///   - placeholder: A view to display while the image is loading.
    public init(
        url: URL?,
        imageLoader: ImageLoader = .shared,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.url = url
        self.imageLoader = imageLoader
        self.placeholder = placeholder()
    }

    public var body: some View {
        GeometryReader { geometry in
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .transition(.opacity.animation(.easeIn(duration: 0.2)))
            } else if loadError != nil {
                errorView
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                placeholder
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .clipped()
        .task(id: url) {
            await loadImage()
        }
    }

    private var errorView: some View {
        Color(.tertiarySystemFill)
            .overlay {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24))
                    .foregroundStyle(Color(.quaternaryLabel))
            }
    }

    @MainActor
    private func loadImage() async {
        guard let url, !isLoading else { return }
        isLoading = true
        image = nil
        loadError = nil

        do {
            let loaded = try await imageLoader.image(for: url)
            if !Task.isCancelled {
                image = loaded
            }
        } catch {
            if !Task.isCancelled {
                loadError = error
            }
        }

        isLoading = false
    }
}

// MARK: - Convenience initializer with default placeholder

public extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    /// Creates a cached async image with a default `ProgressView` placeholder.
    init(url: URL?, imageLoader: ImageLoader = .shared) {
        self.init(url: url, imageLoader: imageLoader) {
            ProgressView()
        }
    }
}
