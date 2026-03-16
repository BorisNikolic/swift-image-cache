
//  UIKitImageListView.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import SwiftUI

struct UIKitImageListView: View {
    @StateObject private var viewModel = ImageListViewModel()

    var body: some View {
        UIKitImageListRepresentable(viewModel: viewModel)
            .ignoresSafeArea(edges: .bottom)
            .task {
                if viewModel.images.isEmpty {
                    await viewModel.fetchImages()
                }
            }
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
        if let vc = nav.viewControllers.first as? UIKitImageListViewController {
            vc.updateImages(viewModel.images)
        }
    }
}

#Preview {
    UIKitImageListView()
}
