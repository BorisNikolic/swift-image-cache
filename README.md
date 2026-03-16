# 🖼️ RoundsImageKit

> A lightweight, zero-dependency image downloading and caching library for iOS.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![iOS 15+](https://img.shields.io/badge/iOS-15%2B-blue.svg)](https://developer.apple.com/ios/)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## ✨ Features

- 🚀 **Async/Await** — Built with Swift concurrency (actors, async/await, Sendable)
- 💾 **Two-Tier Caching** — In-memory (NSCache) + persistent disk cache
- ⏰ **4-Hour TTL** — Cached images automatically expire after 4 hours
- 🔄 **Request Deduplication** — Multiple requests for the same URL share one download
- 🎨 **SwiftUI + UIKit** — `CachedAsyncImage` (SwiftUI) and `UICachedImageView` (UIKit)
- 🧹 **Manual Cache Invalidation** — Clear all caches or remove specific images
- 🧪 **Fully Testable** — Protocol-oriented design with dependency injection
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
        CachedAsyncImage(url: url) {
            ProgressView()
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

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────┐
│                  ImageLoader                  │
│               (actor — main API)              │
├──────────────┬──────────────┬────────────────┤
│ MemoryCache  │  DiskCache   │ ImageDownloader │
│  (NSCache)   │ (FileManager)│  (URLSession)   │
│              │  + 4h TTL    │  + dedup        │
├──────────────┴──────────────┴────────────────┤
│              Protocol Layer                   │
│    ImageCaching      ImageDownloading         │
└──────────────────────────────────────────────┘
```

### Design Principles

| Principle | Implementation |
|-----------|---------------|
| **S** — Single Responsibility | Each class has one job (cache, download, coordinate) |
| **O** — Open/Closed | Extend via protocols, not modification |
| **L** — Liskov Substitution | Mocks seamlessly replace real implementations |
| **I** — Interface Segregation | Small, focused protocols (`ImageCaching`, `ImageDownloading`) |
| **D** — Dependency Inversion | `ImageLoader` depends on abstractions, not concrete types |

### Cache Flow

```
Request → Memory Cache (hit?) → ✅ Return
                  ↓ (miss)
         Disk Cache (hit + valid TTL?) → ✅ Store in memory, Return
                  ↓ (miss or expired)
         Network Download → ✅ Store in both caches, Return
```

---

## 📱 Example App

The included **ExampleApp** demonstrates both SwiftUI and UIKit integration:

### Running the Example

1. Open `ExampleApp/ExampleApp.xcodeproj` in Xcode
2. The local SPM package is already linked
3. Build and run on iOS Simulator (iOS 15+)

### What it shows

| SwiftUI Tab | UIKit Tab |
|-------------|-----------|
| `LazyVGrid` with `CachedAsyncImage` | `UICollectionView` with `UICachedImageView` |
| Pull-to-refresh | `UIRefreshControl` |
| Toolbar cache clear button | Navigation bar cache clear button |
| Gradient ID badges | ID label overlays |

### Testing the Cache

1. **Launch the app** — images load from network (watch the loading indicators)
2. **Scroll through** — all 50 images download and cache
3. **Kill and relaunch** — images load instantly from disk cache
4. **Tap the refresh icon** — clears cache, images re-download
5. **Wait 4 hours** — cached images expire, fresh downloads on next launch

---

## 🧪 Testing

### Run Unit Tests

```bash
# Via Makefile
make test

# Via xcodebuild (iOS simulator required)
xcodebuild test -scheme RoundsImageKitTests \
  -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.6'
```

### Test Coverage

| Suite | Tests | What's Tested |
|-------|-------|---------------|
| `MemoryCacheTests` | 5 | Store, retrieve, remove, clear, independence |
| `DiskCacheTests` | 6 | Store, retrieve, remove, clear, TTL expiry, valid TTL |
| `ImageDownloaderTests` | 4 | Success, invalid data, network error, HTTP 404 |
| `ImageLoaderTests` | 5 | Full flow, memory hit, disk hit, clear, remove |
| **Total** | **20** | |

All tests use **protocol-based mocks** — no mocking frameworks.

---

## 🛠️ Development

### Prerequisites

- Xcode 15+ (Swift 6.0)
- iOS 15+ Simulator

### Setup

```bash
# Install SwiftFormat + SwiftLint
make check-deps

# Install pre-commit hooks (SwiftFormat + SwiftLint)
make hook

# Format code
make format

# Lint code
make lint
```

### Project Structure

```
rounds/
├── 📦 Package.swift              # SPM manifest
├── 📁 Sources/RoundsImageKit/    # SDK source code
│   ├── Cache/                    # MemoryCache, DiskCache, ImageCaching protocol
│   ├── Network/                  # ImageDownloader, ImageDownloading protocol
│   ├── Views/                    # CachedAsyncImage, UICachedImageView
│   └── ImageLoader.swift         # Main public API
├── 🧪 Tests/RoundsImageKitTests/ # Unit tests (Swift Testing)
├── 📱 ExampleApp/                # Demo app (SwiftUI + UIKit)
├── 🤖 .claude/                   # Claude Code config (rules, agents, skills)
├── 📄 CLAUDE.md                  # Project guide for AI assistance
└── ⚙️ BuildTools/                # Pre-commit hook script
```

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

Built with ❤️ by [Boris Nikolic](https://github.com/BorisNikolic)
