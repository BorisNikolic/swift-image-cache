
//  SwiftUIImageGridView.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import RoundsImageKit
import SwiftUI

struct SwiftUIImageGridView: View {
    @ObservedObject var viewModel: ImageListViewModel

    private let columns = [
        GridItem(.flexible(), spacing: Theme.cellSpacing),
        GridItem(.flexible(), spacing: Theme.cellSpacing)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                contentView
                    .padding(.horizontal, Theme.gridPadding)
                    .padding(.vertical, Theme.verticalPadding)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Theme.Strings.appTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.clearCache() }
                    } label: {
                        Image(systemName: Theme.SFSymbol.clearCache)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color(.label))
                    }
                    .accessibilityIdentifier(Theme.AccessibilityID.clearCacheButton)
                    .accessibilityLabel(Theme.Strings.clearCache)
                    .accessibilityHint(Theme.Strings.clearCacheHint)
                }
            }
            .refreshable {
                await viewModel.fetchImages()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.images.isEmpty {
            loadingView
        } else if let error = viewModel.errorMessage, viewModel.images.isEmpty {
            errorView(error)
        } else {
            gridView
        }
    }

    private var loadingView: some View {
        VStack(spacing: Theme.loadingSpacing) {
            ProgressView()
                .scaleEffect(Theme.loadingScaleEffect)
            Text(Theme.Strings.loadingImages)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: Theme.contentMinHeight)
        .accessibilityIdentifier(Theme.AccessibilityID.loadingIndicator)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Theme.Strings.loadingImages)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Theme.loadingSpacing) {
            Image(systemName: Theme.SFSymbol.errorTriangle)
                .font(.system(size: Theme.errorIconSize))
                .foregroundStyle(.orange)

            Text(Theme.Strings.errorTitle)
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(Theme.Strings.retryButton) {
                Task { await viewModel.fetchImages() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentColor)
            .accessibilityIdentifier(Theme.AccessibilityID.retryButton)
            .accessibilityHint(Theme.Strings.retryHint)
        }
        .frame(maxWidth: .infinity, minHeight: Theme.contentMinHeight)
        .accessibilityIdentifier(Theme.AccessibilityID.errorView)
    }

    private var gridView: some View {
        LazyVGrid(columns: columns, spacing: Theme.cellSpacing) {
            ForEach(viewModel.images) { item in
                ImageCell(item: item)
            }
        }
        .accessibilityIdentifier(Theme.AccessibilityID.imageGrid)
    }
}

// MARK: - Image Cell

private struct ImageCell: View {
    let item: ImageItem

    var body: some View {
        CachedAsyncImage(url: item.url) {
            placeholderView
        }
        .aspectRatio(Theme.cellAspectRatio, contentMode: .fill)
        .frame(minHeight: Theme.cellMinHeight)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(alignment: .bottom) {
            gradientOverlay
        }
        .overlay(alignment: .bottomLeading) {
            idBadge
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Color.black.opacity(Theme.borderOpacity), lineWidth: Theme.borderWidth)
        )
        .shadow(color: .black.opacity(Theme.shadowOpacity), radius: Theme.shadowRadius, x: 0, y: Theme.shadowOffsetY)
        .accessibilityIdentifier("\(Theme.AccessibilityID.imageCell)_\(item.id)")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Theme.Strings.imageLabel(item.id))
        .accessibilityHint(Theme.Strings.imageHint)
        .accessibilityAddTraits(.isImage)
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: Theme.cornerRadius)
            .fill(Color(.tertiarySystemFill))
            .overlay {
                Image(systemName: Theme.SFSymbol.photoPlaceholder)
                    .font(.system(size: Theme.placeholderIconSize))
                    .foregroundStyle(Color(.quaternaryLabel))
            }
    }

    private var gradientOverlay: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(Theme.gradientOpacity)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: Theme.cellMinHeight * Theme.gradientHeightMultiplier)
        .allowsHitTesting(false)
    }

    private var idBadge: some View {
        Text(Theme.Strings.imageBadge(item.id))
            .font(.caption2.weight(.bold).monospacedDigit())
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.badgePaddingH)
            .padding(.vertical, Theme.badgePaddingV)
            .background(
                Capsule()
                    .fill(Theme.accentColor)
            )
            .padding(Theme.badgePadding)
            .accessibilityIdentifier(Theme.AccessibilityID.imageBadge)
    }
}

#Preview {
    SwiftUIImageGridView(viewModel: ImageListViewModel())
}
