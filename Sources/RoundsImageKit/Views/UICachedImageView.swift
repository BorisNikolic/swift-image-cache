
//  UICachedImageView.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import UIKit

/// A UIKit view that asynchronously loads and caches an image from a URL.
///
/// Handles cell reuse by cancelling previous loads when a new URL is set.
/// Displays a placeholder image or activity indicator while loading.
///
/// ## Usage
/// ```swift
/// let imageView = UICachedImageView()
/// imageView.placeholder = UIImage(systemName: "photo")
/// imageView.load(from: url)
/// ```
public final class UICachedImageView: UIView {
    private let imageView = UIImageView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var currentTask: Task<Void, Never>?
    private var currentURL: URL?

    /// The image loader used for downloading and caching.
    public var imageLoader: ImageLoader = .shared

    /// Placeholder image shown while the actual image is loading.
    public var placeholder: UIImage? {
        didSet {
            if imageView.image == nil || imageView.image == oldValue {
                imageView.image = placeholder
                imageView.contentMode = .center
            }
        }
    }

    /// Content mode for the displayed image.
    public var imageContentMode: UIView.ContentMode = .scaleAspectFill {
        didSet { imageView.contentMode = imageContentMode }
    }

    /// The currently loaded image.
    public var image: UIImage? {
        imageView.image
    }

    // MARK: - Init

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    /// Loads an image from the given URL.
    ///
    /// Cancels any previous in-flight request. Shows activity indicator during loading.
    /// On success, cross-fades to the loaded image.
    ///
    /// - Parameter url: The remote image URL.
    public func load(from url: URL?) {
        currentTask?.cancel()
        currentTask = nil

        guard let url else {
            imageView.image = placeholder
            imageView.contentMode = .center
            activityIndicator.stopAnimating()
            return
        }

        guard url != currentURL || imageView.image == placeholder else { return }
        currentURL = url

        imageView.image = placeholder
        imageView.contentMode = .center
        activityIndicator.startAnimating()

        currentTask = Task { [weak self] in
            guard let self else { return }

            do {
                let loaded = try await imageLoader.image(for: url)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.imageView.contentMode = self.imageContentMode
                    UIView.transition(
                        with: self.imageView,
                        duration: 0.2,
                        options: .transitionCrossDissolve
                    ) {
                        self.imageView.image = loaded
                    }
                    self.activityIndicator.stopAnimating()
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }

    /// Cancels the current loading task.
    public func cancelLoading() {
        currentTask?.cancel()
        currentTask = nil
        currentURL = nil
        activityIndicator.stopAnimating()
    }

    // MARK: - Reuse

    /// Resets the view for reuse in collection/table view cells.
    /// Call this from your cell's `prepareForReuse()`.
    public func prepareForReuse() {
        cancelLoading()
        imageView.image = placeholder
        imageView.contentMode = .center
    }

    // MARK: - Layout

    private func setupViews() {
        clipsToBounds = true
        imageView.contentMode = imageContentMode
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}
