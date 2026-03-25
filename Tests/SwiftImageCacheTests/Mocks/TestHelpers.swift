//
//  TestHelpers.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import UIKit

enum TestHelpers {
    static func createTestImage(color: UIColor = .red, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    static func createTestImageData(color: UIColor = .red, size: CGSize = CGSize(width: 1, height: 1)) -> Data {
        createTestImage(color: color, size: size).pngData()!
    }
}
