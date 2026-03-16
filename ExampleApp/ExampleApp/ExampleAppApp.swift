//
//  ExampleAppApp.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import SwiftUI

@main
struct ExampleAppApp: App {
    @StateObject private var viewModel: ImageListViewModel

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
        let service: ImageListFetching = isUITesting ? MockImageListService() : ImageListService()
        _viewModel = StateObject(wrappedValue: ImageListViewModel(service: service))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
