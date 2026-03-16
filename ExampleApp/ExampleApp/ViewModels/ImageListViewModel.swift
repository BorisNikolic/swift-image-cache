
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
        isLoading = true
        errorMessage = nil

        do {
            images = try await service.fetchImages()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearCache() async {
        await ImageLoader.shared.clearCache()
        images = []
        await fetchImages()
    }
}
