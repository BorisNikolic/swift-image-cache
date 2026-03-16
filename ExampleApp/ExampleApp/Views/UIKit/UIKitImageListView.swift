//
//  UIKitImageListView.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import SwiftUI

struct UIKitImageListView: View {
    @ObservedObject var viewModel: ImageListViewModel

    var body: some View {
        UIKitImageListRepresentable(viewModel: viewModel)
            .ignoresSafeArea()
    }
}

struct UIKitImageListRepresentable: UIViewControllerRepresentable {
    @ObservedObject var viewModel: ImageListViewModel

    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = UIKitImageListViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: controller)
        nav.navigationBar.prefersLargeTitles = true
        return nav
    }

    func updateUIViewController(_ nav: UINavigationController, context: Context) {
        guard let controller = nav.viewControllers.first as? UIKitImageListViewController else { return }
        controller.updateImages(viewModel.images)

        if let message = viewModel.errorMessage, viewModel.images.isEmpty {
            controller.showError(message)
        } else {
            controller.hideError()
        }

        if !viewModel.isLoading {
            controller.endRefreshing()
        }
    }
}

#Preview {
    UIKitImageListView(viewModel: ImageListViewModel())
}
