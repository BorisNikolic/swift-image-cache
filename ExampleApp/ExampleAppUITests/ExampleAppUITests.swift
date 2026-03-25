//
//  ExampleAppUITests.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import XCTest

final class ExampleAppUITests: XCTestCase {
    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
        return app
    }

    // MARK: - Launch

    @MainActor
    func test_appLaunches_showsTabBar() throws {
        let app = launchApp()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
    }

    @MainActor
    func test_swiftUITab_isSelectedByDefault() throws {
        let app = launchApp()
        let swiftUITab = app.tabBars.buttons["SwiftUI"]
        XCTAssertTrue(swiftUITab.waitForExistence(timeout: 5))
        XCTAssertTrue(swiftUITab.isSelected)
    }

    // MARK: - Tab Navigation

    @MainActor
    func test_switchToUIKitTab() throws {
        let app = launchApp()
        let uikitTab = app.tabBars.buttons["UIKit"]
        XCTAssertTrue(uikitTab.waitForExistence(timeout: 5))
        uikitTab.tap()
        XCTAssertTrue(uikitTab.isSelected)
    }

    @MainActor
    func test_switchBetweenTabs() throws {
        let app = launchApp()
        let swiftUITab = app.tabBars.buttons["SwiftUI"]
        let uikitTab = app.tabBars.buttons["UIKit"]

        XCTAssertTrue(swiftUITab.waitForExistence(timeout: 5))

        uikitTab.tap()
        XCTAssertTrue(uikitTab.isSelected)

        swiftUITab.tap()
        XCTAssertTrue(swiftUITab.isSelected)
    }

    // MARK: - SwiftUI Tab Content

    @MainActor
    func test_swiftUITab_showsNavigationTitle() throws {
        let app = launchApp()
        let title = app.navigationBars["SwiftImageCache"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
    }

    @MainActor
    func test_swiftUITab_showsCacheButton() throws {
        let app = launchApp()
        let cacheButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(cacheButton.waitForExistence(timeout: 10))
    }

    // MARK: - UIKit Tab Content

    @MainActor
    func test_uikitTab_showsNavigationTitle() throws {
        let app = launchApp()
        let uikitTab = app.tabBars.buttons["UIKit"]
        uikitTab.tap()

        let title = app.navigationBars["SwiftImageCache"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
    }

    @MainActor
    func test_uikitTab_showsClearCacheButton() throws {
        let app = launchApp()
        let uikitTab = app.tabBars.buttons["UIKit"]
        uikitTab.tap()

        let clearButton = app.navigationBars.buttons["Clear Cache"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 10))
    }
}
