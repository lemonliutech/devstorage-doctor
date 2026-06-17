# DevStorage Doctor

DevStorage Doctor is a macOS development storage diagnostic and cleanup tool for cross-platform mobile developers.

It focuses on explainable cleanup for reproducible development storage across Xcode, iOS Simulator, Android, Gradle, Flutter, Dart, FVM, CocoaPods, Node, pnpm, npm, HarmonyOS, DevEco, ohpm, and hvigor.

This includes caches, dependency stores, installed toolchain artifacts, project build outputs, and temporary packaging outputs that developers often generate for testing but rarely clean manually.

The product goal is not to be a generic junk cleaner. It should help developers answer:

- What is using disk space?
- Which items are safe to clean or mark for manual review?
- What will be rebuilt or redownloaded afterward?
- Which package outputs were likely created for testing?
- Which active SDKs, simulators, and project environments must be protected?
- Why did a cleanup action fail?

## Product Docs

- [PRD v0.1](docs/superpowers/specs/2026-06-17-devstorage-doctor-prd.md)
- [UX Flow v0.1](docs/superpowers/specs/2026-06-17-devstorage-doctor-ux-flow.md)

## Core Flow

```text
Scan -> Explain -> Risk Grade -> Generate Plan -> Confirm -> Execute -> Report Exceptions
```

## MVP Focus

- Read-only scan first
- Developer-stack grouping
- Risk-based cleanup selection
- Dependency, build artifact, and package output awareness
- Command-level cleanup plan
- Protected active environments
- Named exception reporting
- Copyable cleanup report

## Status

Design phase. No implementation has started yet.
