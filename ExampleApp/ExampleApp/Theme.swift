//
//  Theme.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import SwiftUI
import UIKit

enum Theme {
    // MARK: - Brand Colors

    static let brandPurple = UIColor(red: 0.33, green: 0.24, blue: 0.60, alpha: 1.0)
    static let brandPurpleDark = UIColor(red: 0.21, green: 0.12, blue: 0.35, alpha: 1.0)
    static let brandTeal = UIColor(red: 0.31, green: 0.99, blue: 0.88, alpha: 1.0)

    // MARK: - SwiftUI Colors

    static let accentColor = Color(brandPurple)
    static let accentColorDark = Color(brandPurpleDark)
    static let tealAccent = Color(brandTeal)

    // MARK: - Metrics

    static let cornerRadius: CGFloat = 14
    static let cellSpacing: CGFloat = 12
    static let gridPadding: CGFloat = 16
    static let badgeCornerRadius: CGFloat = 10
    static let shadowRadius: CGFloat = 4
    static let shadowOpacity: CGFloat = 0.08
    static let borderOpacity: CGFloat = 0.06
    static let borderWidth: CGFloat = 0.5
    static let shadowOffsetY: CGFloat = 2
    static let verticalPadding: CGFloat = 10
    static let loadingSpacing: CGFloat = 16
    static let loadingScaleEffect: CGFloat = 1.2
    static let contentMinHeight: CGFloat = 300
    static let errorIconSize: CGFloat = 40
    static let placeholderIconSize: CGFloat = 28
    static let badgePaddingH: CGFloat = 8
    static let badgePaddingV: CGFloat = 4
    static let badgePadding: CGFloat = 8
    static let cellMinHeight: CGFloat = 160
    static let cellAspectRatio: CGFloat = 1
    static let gridItemFraction: CGFloat = 0.5
    static let cellInset: CGFloat = 6
    static let sectionInset: CGFloat = 10
    static let gradientHeightMultiplier: CGFloat = 0.35
    static let gradientOpacity: CGFloat = 0.45
    static let badgeLabelFontSize: CGFloat = 11
    static let badgeLabelHeight: CGFloat = 20
    static let paddedLabelExtraWidth: CGFloat = 16

    // MARK: - SF Symbols

    enum SFSymbol {
        static let clearCache = "arrow.triangle.2.circlepath"
        static let errorTriangle = "exclamationmark.triangle.fill"
        static let photoPlaceholder = "photo"
        static let swiftUITab = "square.grid.2x2.fill"
        static let uikitTab = "uiwindow.split.2x1"
    }

    // MARK: - Strings

    enum Strings {
        static let appTitle = NSLocalizedString("app.title", value: "RoundsImageKit", comment: "Main navigation title")
        static let swiftUITab = NSLocalizedString("tab.swiftui", value: "SwiftUI", comment: "SwiftUI tab title")
        static let uikitTab = NSLocalizedString("tab.uikit", value: "UIKit", comment: "UIKit tab title")
        static let clearCache = NSLocalizedString("action.clearCache", value: "Clear Cache", comment: "Clear cache button title")
        static let loadingImages = NSLocalizedString("loading.images", value: "Loading images...", comment: "Loading indicator text")
        static let errorTitle = NSLocalizedString("error.title", value: "Something went wrong", comment: "Error state title")
        static let retryButton = NSLocalizedString("action.retry", value: "Retry", comment: "Retry button title")

        static func imageBadge(_ id: Int) -> String {
            String(format: NSLocalizedString("image.badge", value: "#%d", comment: "Image ID badge label"), id)
        }

        static func imageLabel(_ id: Int) -> String {
            String(format: NSLocalizedString("accessibility.imageLabel", value: "Image %d", comment: "Accessibility label for image cell"), id)
        }

        // MARK: - Accessibility Hints

        static let clearCacheHint = NSLocalizedString(
            "accessibility.clearCacheHint",
            value: "Clears the image cache and reloads all images",
            comment: "Accessibility hint for clear cache button"
        )
        static let retryHint = NSLocalizedString(
            "accessibility.retryHint",
            value: "Retries loading images",
            comment: "Accessibility hint for retry button"
        )
        static let imageHint = NSLocalizedString(
            "accessibility.imageHint",
            value: "Photo from the image gallery",
            comment: "Accessibility hint for image cell"
        )
    }

    // MARK: - Accessibility IDs

    enum AccessibilityID {
        static let clearCacheButton = "clear_cache_button"
        static let swiftUITab = "tab_swiftui"
        static let uikitTab = "tab_uikit"
        static let imageCell = "image_cell"
        static let imageBadge = "image_badge"
        static let retryButton = "retry_button"
        static let loadingIndicator = "loading_indicator"
        static let errorView = "error_view"
        static let imageGrid = "image_grid"
    }
}
