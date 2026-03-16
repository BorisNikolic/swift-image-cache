
//  SwiftUIImageGridView.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import SwiftUI
import RoundsImageKit

struct SwiftUIImageGridView: View {
    @StateObject private var viewModel = ImageListViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    contentView
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("RoundsImageKit")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.clearCache() }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.body.weight(.medium))
                    }
                }
            }
            .refreshable {
                await viewModel.fetchImages()
            }
            .task {
                if viewModel.images.isEmpty {
                    await viewModel.fetchImages()
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Image Caching Demo", systemImage: "photo.stack")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.indigo)

            Text("Demonstrating two-tier caching (memory + disk) with async loading, request deduplication, and cross-fade transitions.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.top, 8)
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
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading images...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text("Something went wrong")
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task { await viewModel.fetchImages() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private var gridView: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(viewModel.images) { item in
                ImageCell(item: item)
            }
        }
    }
}

// MARK: - Image Cell

private struct ImageCell: View {
    let item: ImageItem

    var body: some View {
        CachedAsyncImage(url: item.url) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.tertiarySystemFill))
                .overlay {
                    ProgressView()
                        .tint(.secondary)
                }
        }
        .aspectRatio(1, contentMode: .fill)
        .frame(minHeight: 160)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .bottomLeading) {
            idBadge
        }
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
    }

    private var idBadge: some View {
        Text("#\(item.id)")
            .font(.caption2.weight(.bold).monospacedDigit())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .padding(8)
    }
}

#Preview {
    SwiftUIImageGridView()
}
