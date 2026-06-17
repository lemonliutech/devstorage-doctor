# DevCache Doctor

DevCache Doctor is a macOS developer-environment cache diagnostic and cleanup tool for cross-platform mobile developers.

It focuses on explainable cleanup for development caches across Xcode, iOS Simulator, Android, Gradle, Flutter, Dart, FVM, CocoaPods, Node, pnpm, npm, HarmonyOS, DevEco, ohpm, and hvigor.

The product goal is not to be a generic junk cleaner. It should help developers answer:

- What is using disk space?
- Which items are safe to clean?
- What will be rebuilt or redownloaded afterward?
- Which active SDKs, simulators, and project environments must be protected?
- Why did a cleanup action fail?

## Product Docs

- [PRD v0.1](docs/superpowers/specs/2026-06-17-devcache-doctor-prd.md)
- [UX Flow v0.1](docs/superpowers/specs/2026-06-17-devcache-doctor-ux-flow.md)

## Core Flow

```text
Scan -> Explain -> Risk Grade -> Generate Plan -> Confirm -> Execute -> Report Exceptions
```

## MVP Focus

- Read-only scan first
- Developer-stack grouping
- Risk-based cleanup selection
- Command-level cleanup plan
- Protected active environments
- Named exception reporting
- Copyable cleanup report

## Status

Design phase. No implementation has started yet.
