//
//  ImageListViewModel.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import Combine
import Foundation
import RoundsImageKit

@MainActor
final class ImageListViewModel: ObservableObject {
    @Published private(set) var images: [ImageItem] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let service: ImageListFetching

    init(service: ImageListFetching = ImageListService()) {
        self.service = service
    }

    func fetchImages() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await performFetch()
            images = fetched
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearCache() async {
        await ImageLoader.shared.clearCache()
        isLoading = false
        images = []
        await fetchImages()
    }

    /// Runs network + JSON decode off the main actor.
    private nonisolated func performFetch() async throws -> [ImageItem] {
        try await service.fetchImages()
    }
}
