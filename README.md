# 🖼️ RoundsImageKit

> A lightweight, zero-dependency image downloading and caching library for iOS.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![iOS 15+](https://img.shields.io/badge/iOS-15%2B-blue.svg)](https://developer.apple.com/ios/)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![CI](https://github.com/BorisNikolic/rounds/actions/workflows/ci.yml/badge.svg)](https://github.com/BorisNikolic/rounds/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## ✨ Features

- 🚀 **Swift 6 Concurrency** — Actors, async/await, Sendable, `@MainActor` throughout
- 💾 **Two-Tier Caching** — In-memory (`NSCache`) + persistent disk cache
- 📂 **Format-Preserving Storage** — Stores original bytes (PNG, JPEG, WebP) — no re-encoding
- ⏰ **4-Hour TTL** — Disk-cached images expire automatically; configurable via `ImageLoader.Configuration`
- 🔄 **Cancellation-Safe Deduplication** — Shared downloads survive individual caller cancellation (e.g. cell reuse during scroll)
- 📐 **Automatic Downsampling** — Images are thumbnailed to screen dimensions before memory caching, reducing decoded size from ~12MB to ~1-2MB per image
- 🗂️ **Disk Size Limit with LRU Eviction** — Configurable disk quota (default 100MB) with oldest-first eviction and 70% trim ratio
- ⚡ **Synchronous Cache Lookup** — `cachedImage(for:)` enables instant display in SwiftUI body / UIKit cell binding with zero async overhead
- 🎨 **SwiftUI + UIKit** — `CachedAsyncImage` and `UICachedImageView` with identical visual behavior
- 🧹 **Manual Cache Invalidation** — Clear all caches or remove specific images
- ⚙️ **Configurable** — `ImageLoader.Configuration` for TTL, memory/disk limits, thumbnail dimension
- 🧪 **Fully Testable** — Split protocols (`MemoryImageCaching`, `DiskImageCaching`, `ImageDownloading`) with dependency injection
- 🌍 **Localized** — All strings via `NSLocalizedString`, English `.strings` file included
- ♿ **Accessible** — VoiceOver labels, hints, traits, and identifiers on all elements
- 📦 **Zero Dependencies** — No third-party libraries required
- 🏗️ **SOLID Architecture** — Clean, scalable, protocol-driven design

---

## 📦 Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/BorisNikolic/rounds.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** → paste the repository URL.

---

## 🚀 Quick Start

### SwiftUI

```swift
import RoundsImageKit

struct ImageView: View {
    let url: URL

    var body: some View {
        // Placeholder can be any SwiftUI view — shown while loading
        CachedAsyncImage(url: url) {
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

### UIKit

```swift
import RoundsImageKit

let imageView = UICachedImageView()
imageView.placeholder = UIImage(systemName: "photo")
imageView.load(from: url)
```

### Direct API

```swift
import RoundsImageKit

// Load an image
let image = try await ImageLoader.shared.image(for: url)

// Clear all caches
await ImageLoader.shared.clearCache()

// Remove a specific cached image
await ImageLoader.shared.removeCachedImage(for: url)
```

### Custom Configuration

```swift
import RoundsImageKit

let loader = ImageLoader(configuration: .init(
    ttl: 2 * 60 * 60,              // 2-hour TTL
    memoryCacheCountLimit: 50,       // max 50 images in memory
    memoryCacheSizeLimit: 100_000_000, // 100 MB memory limit
    diskCacheSizeLimit: 50_000_000,  // 50 MB disk limit
    maxThumbnailDimension: 512       // downsample to 512pt max
))
let image = try await loader.image(for: url)
```

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────┐
│                   ImageLoader                     │
│            (actor — main public API)              │
│    Configuration: TTL, memory/disk limits,        │
│    thumbnail dimension, LRU eviction              │
├────────────────┬────────────┬────────────────────┤
│  MemoryCache   │ DiskCache  │  ImageDownloader    │
│   (NSCache)    │(FileManager)│   (URLSession)     │
│ downsampled    │raw bytes   │ Task.detached dedup │
│ sync lookup    │size limit  │ cancellation-safe   │
├────────────────┴────────────┴────────────────────┤
│               Protocol Layer                      │
│  MemoryImageCaching    DiskImageCaching           │
│                   ImageDownloading                │
└──────────────────────────────────────────────────┘
```

### Design Principles

| Principle | Implementation |
|-----------|---------------|
| **S** — Single Responsibility | Each class has one job (cache, download, coordinate) |
| **O** — Open/Closed | Extend via protocols, not modification |
| **L** — Liskov Substitution | Mocks seamlessly replace real implementations |
| **I** — Interface Segregation | Separate protocols: `MemoryImageCaching` (UIImage), `DiskImageCaching` (Data) |
| **D** — Dependency Inversion | `ImageLoader` depends on abstractions, not concrete types |

### Cache Flow

```
Request → Sync Memory Check (hit?) → ✅ Return instantly (no async)
                  ↓ (miss)
         Async Memory Cache (hit?) → ✅ Return UIImage
                  ↓ (miss)
         Disk Cache (hit + valid TTL?) → ✅ Downsample → Promote to memory, Return
                  ↓ (miss or expired)
         Network Download → ✅ Downsample to memory, raw Data to disk, Return
```

### Cancellation-Safe Deduplication

```
Cell A requests image.png → starts Task.detached download
Cell B requests image.png → joins existing task (no duplicate request)
Cell A scrolls off-screen → cancels its await, download continues
Cell B receives the image → download cleans up from map
```

---

## 📱 Example App

The included **ExampleApp** demonstrates both SwiftUI and UIKit integration with identical visual design:

### Running the Example

1. Open `ExampleApp/ExampleApp.xcodeproj` in Xcode
2. The local SPM package is already linked
3. Build and run on iOS Simulator (iOS 15+)

### What It Demonstrates

| Feature | SwiftUI Tab | UIKit Tab |
|---------|-------------|-----------|
| **Image Grid** | `LazyVGrid` + `CachedAsyncImage` | `UICollectionViewCompositionalLayout` + `UICachedImageView` |
| **Placeholder** | Photo icon + spinner | Photo icon + activity indicator |
| **Error State** | Placeholder stays visible | Error view with retry button (app-level) |
| **Pull to Refresh** | `.refreshable` | `UIRefreshControl` |
| **Cache Clear** | Toolbar button | Navigation bar button |
| **ID Badges** | Capsule with gradient | Rounded label |
| **Accessibility** | VoiceOver labels, hints, traits | `isAccessibilityElement`, labels, hints |
| **Localization** | `NSLocalizedString` via Theme | Same strings via Theme |
| **Prefetching** | SwiftUI `LazyVGrid` (automatic) | `UICollectionViewDataSourcePrefetching` |

### App Architecture

- **MVVM** with shared `ImageListViewModel` across both tabs
- **Protocol-based service** (`ImageListFetching`) with mock injection for testing
- **Centralized Theme** — all colors, metrics, strings, SF Symbols, and accessibility IDs
- **`en.lproj/Localizable.strings`** for English localization

### Testing the Cache

1. **Launch the app** — images load from network with placeholder spinners
2. **Scroll through** — all 50 images download and cache (request deduplication in action)
3. **Kill and relaunch** — images load instantly from disk cache (no spinners)
4. **Tap the refresh icon** — clears cache, images re-download
5. **Wait 4 hours** — cached images expire, fresh downloads on next launch

---

## 🧪 Testing

### Run Tests

```bash
# SDK unit tests (via Makefile)
make test

# SDK unit tests (via xcodebuild)
xcodebuild test -scheme RoundsImageKit \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'

# ExampleApp unit tests
xcodebuild test -project ExampleApp/ExampleApp.xcodeproj \
  -scheme ExampleApp -only-testing:ExampleAppTests \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'
```

### Test Coverage

| Suite | Tests | What's Tested |
|-------|-------|---------------|
| **SDK Tests** | | |
| `MemoryCacheTests` | 5 | Store, retrieve, remove, clear, independence |
| `DiskCacheTests` | 8 | Store, retrieve, remove, clear, TTL expiry, valid TTL, size eviction, sweep |
| `ImageDownloaderTests` | 4 | Success, invalid data, network error, HTTP 404 |
| `ImageLoaderTests` | 5 | Full flow, memory hit, disk hit, clear, remove |
| **App Tests** | | |
| `ImageItemTests` | 5 | JSON decoding, URL parsing, empty string, identifiable, hashable |
| `ImageListViewModelTests` | 5 | Fetch success, loading state, error, clearCache, overlap guard |
| **Total** | **32** | |

- All SDK tests use **protocol-based mocks** — no mocking frameworks
- ViewModel tests use `MockImageListService` — no network calls
- UI tests inject mock service via `--uitesting` launch argument — deterministic, no flaky network

---

## 🔄 CI/CD

**GitHub Actions** runs on every push and PR to `main`:

| Job | What it does |
|-----|--------------|
| **Lint** | SwiftFormat `--lint` + SwiftLint `--strict` on all Swift files |
| **Test** | Build SDK + run 20 unit tests on iOS Simulator |

CI status badge is shown at the top of this README.

---

## 🛠️ Development

### Prerequisites

- Xcode 15+ (Swift 6.0)
- iOS 15+ Simulator
- SwiftFormat + SwiftLint (installed via `make check-deps`)

### Setup

```bash
# Install SwiftFormat + SwiftLint
make check-deps

# Install pre-commit hooks
make hook

# Format code
make format

# Lint code
make lint

# Run SDK tests
make test

# Clean build artifacts
make clean
```

### Code Quality Hooks

| Hook | When | What |
|------|------|------|
| **Git pre-commit** | Every `git commit` | SwiftFormat auto-fix + SwiftLint strict on staged `.swift` files |
| **Claude Code PostToolUse** | Every `.swift` file edit by Claude | Auto-formats via SwiftFormat |
| **GitHub Actions CI** | Every push/PR to `main` | Lint + test (see CI/CD section) |

Install the pre-commit hook with `make hook`.

### Project Structure

```
rounds/
├── 📦 Package.swift                  # SPM manifest (swift-tools-version: 6.0)
├── 📁 Sources/RoundsImageKit/        # SDK source code
│   ├── Cache/                        # MemoryImageCaching, DiskImageCaching protocols
│   │   ├── MemoryCache.swift         # NSCache wrapper (stores UIImage)
│   │   ├── DiskCache.swift           # FileManager + SHA256 + TTL (stores raw Data)
│   │   └── CacheEntry.swift          # Codable metadata (timestamp, size)
│   ├── Network/                      # ImageDownloading protocol
│   │   └── ImageDownloader.swift     # URLSession + Task.detached dedup
│   ├── Views/                        # UI components
│   │   ├── CachedAsyncImage.swift    # SwiftUI view
│   │   └── UICachedImageView.swift   # UIKit view
│   └── ImageLoader.swift             # Main API (actor + Configuration)
├── 🧪 Tests/RoundsImageKitTests/     # 20 SDK unit tests (Swift Testing)
│   ├── Cache/                        # MemoryCache + DiskCache tests
│   ├── Network/                      # ImageDownloader tests
│   ├── Mocks/                        # Protocol-based mocks
│   └── ImageLoaderTests.swift        # Integration tests
├── 📱 ExampleApp/                    # Demo app (SwiftUI + UIKit)
│   ├── ExampleApp/                   # App source
│   │   ├── Theme.swift               # Centralized colors, metrics, strings, a11y IDs
│   │   ├── Models/                   # ImageItem (Codable)
│   │   ├── Services/                 # ImageListService + MockImageListService
│   │   ├── ViewModels/               # ImageListViewModel (@MainActor)
│   │   ├── Views/SwiftUI/            # SwiftUI image grid
│   │   ├── Views/UIKit/              # UIKit collection view
│   │   └── en.lproj/                 # English localization
│   ├── ExampleAppTests/              # 10 unit tests (ImageItem + ViewModel)
│   └── ExampleAppUITests/            # 8 UI tests (stubbed network)
├── 🤖 .claude/                       # Claude Code config
│   └── rules/                        # Coding style, architecture, testing rules
├── ⚙️ .github/workflows/ci.yml       # GitHub Actions CI pipeline
├── ⚙️ BuildTools/                     # Pre-commit hook script
├── 📄 CLAUDE.md                      # Project guide for AI assistance
├── 📄 Makefile                       # check-deps, hook, test, lint, format, clean
├── 📄 .swiftformat                   # SwiftFormat config
├── 📄 .swiftlint.yml                 # SwiftLint config
└── 📄 LICENSE                        # MIT
```

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

Built with ❤️ by [Boris Nikolic](https://github.com/BorisNikolic)
