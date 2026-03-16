# RoundsImageKit — Project Guide

Lightweight image downloading and caching library for iOS, with an example app demonstrating both SwiftUI and UIKit integration.

## Project Structure

```
rounds/
├── Package.swift                     # SPM manifest (swift-tools-version: 6.0)
├── RoundsImageKit.podspec            # CocoaPods spec (v1.0.0)
├── Sources/RoundsImageKit/           # SDK source code
│   ├── Cache/                        # ImageCaching protocol, MemoryCache, DiskCache
│   ├── Network/                      # ImageDownloading protocol, ImageDownloader
│   ├── Views/                        # CachedAsyncImage (SwiftUI), UICachedImageView (UIKit)
│   └── ImageLoader.swift             # Main public API (actor)
├── Tests/RoundsImageKitTests/        # Unit tests (Swift Testing)
├── ExampleApp/                       # Xcode project with SwiftUI + UIKit demo
├── BuildTools/                       # Pre-commit hook script
└── .claude/                          # Claude Code config (rules, agents, skills)
```

## Architecture

- **Protocol-Oriented**: `ImageCaching`, `ImageDownloading` protocols for DI and testability
- **Actor-based**: `ImageLoader` and `ImageDownloader` use Swift actors for thread safety
- **Two-tier cache**: Memory (NSCache) → Disk (FileManager + SHA256 + 4h TTL) → Network
- **SOLID principles**: Single responsibility per class, dependency inversion via protocols
- **No 3rd party dependencies**

## Quick Reference

```bash
# Build SDK
xcodebuild build -scheme RoundsImageKit \
  -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.6'

# Run unit tests
xcodebuild test -scheme RoundsImageKitTests \
  -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.6'

# Build example app
xcodebuild build -scheme ExampleApp \
  -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.6'

# Code quality
make lint      # SwiftLint
make format    # SwiftFormat
make hook      # Install pre-commit hooks
make test      # Run tests (requires iOS simulator for UIKit tests)
```

## Conventions

- Swift 6.0, iOS 15+ deployment target
- No `internal` modifier (it's the default) — use `public` for public API
- `if let x { }` shorthand
- Omit `return` in single-expression bodies
- `final` on classes, `let` over `var`
- Conventional commits: `feat:`, `fix:`, `test:`, `chore:`, `docs:`
- Tests use Swift Testing framework (@Test, #expect)
- Protocol-based mocks, no mocking frameworks

## JSON Endpoint

```
https://zipoapps-storage-test.nyc3.digitaloceanspaces.com/image_list.json
```

Returns `[{"id": Int, "imageUrl": String}]` with 50 images.
