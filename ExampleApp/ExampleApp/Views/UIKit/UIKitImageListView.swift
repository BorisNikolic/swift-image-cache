
//  UIKitImageListView.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import SwiftUI

struct UIKitImageListView: View {
    @ObservedObject var viewModel: ImageListViewModel

    var body: some View {
        UIKitImageListRepresentable(viewModel: viewModel)
            .ignoresSafeArea(edges: .bottom)
    }
}

struct UIKitImageListRepresentable: UIViewControllerRepresentable {
    @ObservedObject var viewModel: ImageListViewModel

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = UIKitImageListViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.prefersLargeTitles = true
        return nav
    }

    func updateUIViewController(_ nav: UINavigationController, context: Context) {
        guard let vc = nav.viewControllers.first as? UIKitImageListViewController else { return }
        vc.updateImages(viewModel.images)

        if let message = viewModel.errorMessage, viewModel.images.isEmpty {
            vc.showError(message)
        } else {
            vc.hideError()
        }

        if !viewModel.isLoading {
            vc.endRefreshing()
        }
    }
}

#Preview {
    UIKitImageListView(viewModel: ImageListViewModel())
}
