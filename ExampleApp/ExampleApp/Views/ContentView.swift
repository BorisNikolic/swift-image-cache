//
//  ContentView.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: ImageListViewModel

    var body: some View {
        TabView {
            SwiftUIImageGridView(viewModel: viewModel)
                .tabItem {
                    Label(Theme.Strings.swiftUITab, systemImage: Theme.SFSymbol.swiftUITab)
                }
                .accessibilityIdentifier(Theme.AccessibilityID.swiftUITab)

            UIKitImageListView(viewModel: viewModel)
                .tabItem {
                    Label(Theme.Strings.uikitTab, systemImage: Theme.SFSymbol.uikitTab)
                }
                .accessibilityIdentifier(Theme.AccessibilityID.uikitTab)
        }
        .tint(Theme.accentColor)
        .task {
            if viewModel.images.isEmpty {
                await viewModel.fetchImages()
            }
        }
    }
}

#Preview {
    ContentView(viewModel: ImageListViewModel())
}
