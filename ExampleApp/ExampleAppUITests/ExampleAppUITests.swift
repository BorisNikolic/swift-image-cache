
//  ExampleAppUITests.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import XCTest

final class ExampleAppUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Launch

    @MainActor
    func test_appLaunches_showsTabBar() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
    }

    @MainActor
    func test_swiftUITab_isSelectedByDefault() throws {
        let swiftUITab = app.tabBars.buttons["SwiftUI"]
        XCTAssertTrue(swiftUITab.waitForExistence(timeout: 5))
        XCTAssertTrue(swiftUITab.isSelected)
    }

    // MARK: - Tab Navigation

    @MainActor
    func test_switchToUIKitTab() throws {
        let uikitTab = app.tabBars.buttons["UIKit"]
        XCTAssertTrue(uikitTab.waitForExistence(timeout: 5))
        uikitTab.tap()
        XCTAssertTrue(uikitTab.isSelected)
    }

    @MainActor
    func test_switchBetweenTabs() throws {
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
        let title = app.navigationBars["RoundsImageKit"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
    }

    @MainActor
    func test_swiftUITab_showsCacheButton() throws {
        let cacheButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(cacheButton.waitForExistence(timeout: 10))
    }

    // MARK: - UIKit Tab Content

    @MainActor
    func test_uikitTab_showsNavigationTitle() throws {
        let uikitTab = app.tabBars.buttons["UIKit"]
        uikitTab.tap()

        let title = app.navigationBars["RoundsImageKit"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
    }

    @MainActor
    func test_uikitTab_showsClearCacheButton() throws {
        let uikitTab = app.tabBars.buttons["UIKit"]
        uikitTab.tap()

        let clearButton = app.navigationBars.buttons["Clear Cache"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 10))
    }
}
