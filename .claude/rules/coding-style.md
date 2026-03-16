---
description: Swift coding conventions for the RoundsImageKit project
globs: Sources/**/*.swift, Tests/**/*.swift, ExampleApp/**/*.swift
---

# Swift Coding Style

## Syntax

- `if let x { }` not `if let x = x { }`
- Omit `return` in single-expression computed properties, closures, and `get` blocks
- Omit unnecessary `self` — only use where the compiler requires it
- Use `[self]` over `[weak self]` in Task closures within actors/classes (no retain cycle risk)
- Prefer implicit member expressions: `.systemBackground` over `UIColor.systemBackground`
- Use `\.keyPath` method references where possible
- Use `isEmpty` over `count == 0`
- Use `compactMap` not `map().filter().map()`

## Member Ordering (within a type)

1. Public stored properties
2. Public computed properties
3. Private/internal stored properties
4. Initializers
5. Public methods
6. Private/internal methods
7. Extensions (protocol conformances)

## Access Control

- Default to `private` for all properties and methods
- Widen to `public` only when the API needs it
- Never write `internal` — it is the default modifier
- No redundant access modifiers in extensions that already specify access

## Type Design

- `final` on all classes by default
- `let` over `var` — use var only when mutation is required
- Use caseless `enum` for namespaces (e.g., `enum Constants { }`)
- Prefer `struct` over `class` unless reference semantics are needed
- Use `actor` for thread-safe mutable state

## Linting

Rules are enforced by `.swiftlint.yml` and `.swiftformat` — run `make format` and `make lint` before committing.

## Code Minimalism

- No verbose comments — only explain "why", never "what"
- Don't extract a variable if it's only used on the next line
- Use ternaries for simple conditional assignments
- Prefer `guard let` for early exits over nested `if let`
