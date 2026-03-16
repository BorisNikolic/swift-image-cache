---
description: Testing patterns and conventions
globs: Tests/**/*.swift
---

# Testing Conventions

## Framework
- Use Swift Testing (`import Testing`, `@Test`, `#expect`, `@Suite`)
- NOT XCTest

## Naming
- Test files: `{Subject}Tests.swift`
- Test methods: `test_{context}_{condition}_{expectedResult}`
- Mock files: `Mock{Protocol}.swift`
- Helpers: `TestHelpers.swift`

## Mock Approach
- Protocol-based mocks, no mocking frameworks
- Configurable return values via properties
- Call tracking: `{method}CallCount`, `{method}CalledWith` arrays
- Keep mocks minimal — only what tests need

## Test Structure (Given/When/Then)
```swift
@Test func test_loadImage_cacheEmpty_downloadsFromNetwork() async throws {
    // Given
    let mockCache = MockImageCache()
    let mockDownloader = MockImageDownloader()
    mockDownloader.resultToReturn = .success(testImage)
    let loader = ImageLoader(memoryCache: mockCache, diskCache: mockCache, downloader: mockDownloader)

    // When
    let image = try await loader.image(for: testURL)

    // Then
    #expect(image != nil)
    #expect(mockDownloader.downloadCallCount == 1)
}
```

## Running Tests
```bash
# All SDK unit tests
xcodebuild test -scheme RoundsImageKitTests \
  -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.6' \
  2>&1 | grep -E "Test case|passed|failed|error:"

# Via swift test (macOS only — won't work for UIKit-dependent tests)
# swift test
```

## Test Coverage Priorities
1. Happy path (expected inputs → expected outputs)
2. Error paths (invalid data, network failures)
3. Edge cases (empty cache, expired TTL, concurrent access)
4. Cache behavior (memory → disk → network flow)
