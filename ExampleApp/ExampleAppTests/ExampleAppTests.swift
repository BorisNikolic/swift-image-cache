
//  ExampleAppTests.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import Foundation
import Testing
@testable import ExampleApp

struct ImageItemTests {
    @Test func test_decodingFromJSON() throws {
        let json = """
        {"id": 1, "imageUrl": "https://example.com/image.jpg"}
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(ImageItem.self, from: json)
        #expect(item.id == 1)
        #expect(item.imageUrl == "https://example.com/image.jpg")
    }

    @Test func test_urlParsing_validURL() {
        let item = ImageItem(id: 0, imageUrl: "https://example.com/photo.jpg")
        #expect(item.url != nil)
        #expect(item.url?.absoluteString == "https://example.com/photo.jpg")
    }

    @Test func test_urlParsing_emptyString() {
        let item = ImageItem(id: 0, imageUrl: "")
        #expect(item.url == nil)
    }

    @Test func test_identifiable_usesIdProperty() {
        let item = ImageItem(id: 42, imageUrl: "https://example.com/image.jpg")
        #expect(item.id == 42)
    }

    @Test func test_hashable_sameContentIsEqual() {
        let item1 = ImageItem(id: 1, imageUrl: "https://example.com/a.jpg")
        let item2 = ImageItem(id: 1, imageUrl: "https://example.com/a.jpg")
        #expect(item1 == item2)
        #expect(item1.hashValue == item2.hashValue)
    }
}
