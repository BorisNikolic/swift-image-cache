
//  ImageListViewModelTests.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import Foundation
import Testing
@testable import ExampleApp

struct ImageListViewModelTests {
    @Test @MainActor func test_fetchImages_success() async {
        let viewModel = ImageListViewModel(service: MockImageListService())

        await viewModel.fetchImages()

        #expect(!viewModel.images.isEmpty)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isLoading)
    }

    @Test @MainActor func test_fetchImages_setsIsLoading() async {
        let viewModel = ImageListViewModel(service: MockImageListService())

        #expect(!viewModel.isLoading)
        await viewModel.fetchImages()
        #expect(!viewModel.isLoading)
    }

    @Test @MainActor func test_fetchImages_error() async {
        let viewModel = ImageListViewModel(service: FailingImageListService())

        await viewModel.fetchImages()

        #expect(viewModel.images.isEmpty)
        #expect(viewModel.errorMessage != nil)
    }

    @Test @MainActor func test_clearCache_refetches() async {
        let viewModel = ImageListViewModel(service: MockImageListService())

        await viewModel.fetchImages()
        #expect(!viewModel.images.isEmpty)

        await viewModel.clearCache()
        #expect(!viewModel.images.isEmpty)
    }

    @Test @MainActor func test_fetchImages_guardsOverlapping() async {
        let viewModel = ImageListViewModel(service: MockImageListService())

        async let first: Void = viewModel.fetchImages()
        async let second: Void = viewModel.fetchImages()
        _ = await (first, second)

        #expect(!viewModel.images.isEmpty)
    }
}

final class FailingImageListService: ImageListFetching, @unchecked Sendable {
    func fetchImages() async throws -> [ImageItem] {
        throw URLError(.notConnectedToInternet)
    }
}
