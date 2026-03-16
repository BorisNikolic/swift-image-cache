
//  ContentView.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SwiftUIImageGridView()
                .tabItem {
                    Label(Theme.Strings.swiftUITab, systemImage: Theme.SFSymbol.swiftUITab)
                }
                .accessibilityIdentifier(Theme.AccessibilityID.swiftUITab)

            UIKitImageListView()
                .tabItem {
                    Label(Theme.Strings.uikitTab, systemImage: Theme.SFSymbol.uikitTab)
                }
                .accessibilityIdentifier(Theme.AccessibilityID.uikitTab)
        }
        .tint(.indigo)
    }
}

#Preview {
    ContentView()
}
