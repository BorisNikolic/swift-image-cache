
//  ContentView.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SwiftUIImageGridView()
                .tabItem {
                    Label("SwiftUI", systemImage: "square.grid.2x2.fill")
                }

            UIKitImageListView()
                .tabItem {
                    Label("UIKit", systemImage: "uiwindow.split.2x1")
                }
        }
        .tint(.indigo)
    }
}

#Preview {
    ContentView()
}
