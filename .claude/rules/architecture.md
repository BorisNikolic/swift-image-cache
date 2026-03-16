---
description: SDK architecture and design principles
globs: Sources/**/*.swift
---

# RoundsImageKit Architecture

## Design Principles

- **SOLID**: Each class has a single responsibility, open for extension, depends on abstractions
- **Protocol-Oriented**: All major components have protocol abstractions for testability
- **No Subclassing**: Prefer composition and protocol conformance over inheritance
- **Actor-based Concurrency**: Thread safety via Swift actors, not locks/queues

## Component Overview

### ImageLoader (actor) — Main Entry Point
- Coordinates memory cache → disk cache → network download
- Request deduplication via in-flight task map
- Dependency injection via init (all dependencies are protocols)
- `static let shared` convenience, but always allow custom instances

### Cache Layer
- `ImageCaching` protocol — abstraction for any cache implementation
- `MemoryCache` — NSCache wrapper, auto-evicts on memory pressure
- `DiskCache` — FileManager + CryptoKit SHA256, 4-hour TTL via metadata files

### Network Layer
- `ImageDownloading` protocol — abstraction for network downloads
- `ImageDownloader` (actor) — URLSession-based with request deduplication

### View Layer
- `CachedAsyncImage` — SwiftUI view with placeholder builder
- `UICachedImageView` — UIKit UIView subclass for collection/table view cells

## Error Handling
- `ImageLoadingError` enum covers all failure cases
- Errors are thrown, never silently swallowed (except cache write failures)
- Views handle errors gracefully — show placeholder on failure

## Public API Conventions
- Mark all public API with `public`
- Never use `internal` (it's the default)
- Actor isolation for thread safety
- Sendable conformance on all protocol types
