# DevCache Doctor PRD v0.1

## 1. Product Summary

**Product name:** DevCache Doctor

**Theme:** 多端开发者 macOS 缓存清理工具

**Positioning:** A macOS developer-environment cache diagnostic and cleanup tool for cross-platform mobile developers. It helps users understand disk usage, classify cleanup risk, generate an auditable cleanup plan, and safely recover disk space.

DevCache Doctor is not a generic "junk cleaner". It focuses on developer caches and toolchain artifacts that are large, confusing, and often safe to rebuild, but risky to delete blindly.

## 2. Problem

Multi-platform developers routinely accumulate tens or hundreds of gigabytes of cache across:

- Xcode and iOS Simulator
- Android SDK, Emulator, and Gradle
- Flutter, Dart, and FVM
- CocoaPods
- Node, npm, and pnpm
- HarmonyOS, DevEco, ohpm, and hvigor
- Docker, virtual machines, and large project folders

When disk space is nearly full, developers know that some of this data is disposable, but they often do not know:

- what each directory is for
- whether deletion will break current projects
- whether the data can be regenerated
- how much rebuild or redownload cost deletion causes
- which SDKs, simulators, or package caches are actively used
- why a cleanup command failed

The current alternatives are either too narrow, such as Xcode-only cleaners, or too generic, such as broad disk cleanup tools that do not understand development workflows.

## 3. Target Users

### Primary User

Cross-platform mobile developers on macOS who work with multiple toolchains.

Common stack:

- Xcode / iOS Simulator
- Android Studio / Android SDK
- Flutter / Dart / FVM
- Gradle / CocoaPods
- Node / pnpm / npm
- HarmonyOS / DevEco / OHOS tooling

### Secondary User

Technical leads or senior engineers who help teammates recover disk space without breaking local development environments.

## 4. Jobs To Be Done

When my Mac disk is almost full, I want to know which developer caches are safe to remove, so that I can recover space without breaking my current projects.

When I see a huge directory, I want to understand what produced it and whether it is rebuildable, so that I do not delete important project or SDK data by mistake.

When cleanup fails, I want to see the exact exception and suggested fix, so that I can resolve the real problem instead of repeatedly trying fallback deletes.

## 5. Product Principles

1. **Explain before clean**
   Every cleanup item must explain what it is, why it exists, what deletes it, and what happens afterward.

2. **Risk-first selection**
   Low-risk items may be selected by default. Medium-risk items require explicit user selection. High-risk and non-cache items are suggestions only.

3. **Developer-context aware**
   The app should detect active projects, booted simulators, current FVM versions, installed SDKs, package managers, and tool availability.

4. **Auditable execution**
   The app generates a cleanup plan before execution and records success, skipped items, failures, and exceptions after execution.

5. **No destructive guessing**
   If the app cannot classify a directory safely, it must not delete it automatically.

## 6. MVP Scope

### Xcode / iOS

Included:

- `~/Library/Developer/Xcode/DerivedData`
- `~/Library/Developer/Xcode/NewDerivedData`
- Xcode module caches
- unavailable iOS Simulator devices via `xcrun simctl delete unavailable`
- iOS Simulator device data size analysis
- `~/Library/Developer/Xcode/iOS DeviceSupport` analysis

MVP behavior:

- DerivedData and unavailable simulators can be low-risk cleanup candidates.
- Booted simulators must be protected.
- DeviceSupport should default to manual review because it may be needed for physical-device debugging.

### Android / Gradle

Included:

- `~/.gradle/caches`
- `~/.gradle/daemon`
- `~/.gradle/wrapper`
- Android SDK size analysis
- Android NDK versions
- Android system images
- Emulator images

MVP behavior:

- Gradle daemon cleanup is low risk.
- Gradle caches are medium risk because dependencies may need to redownload.
- NDK and system image cleanup require manual selection.

### Flutter / Dart / FVM

Included:

- `~/.pub-cache/hosted`
- `~/.pub-cache/git`
- FVM versions
- Flutter SDK cache analysis
- project build artifact detection where a project root is selected

MVP behavior:

- Pub cache cleanup is medium risk.
- Current FVM SDK versions must be protected.
- Unused FVM versions can be suggested, but not selected by default.

### CocoaPods

Included:

- CocoaPods cache
- CocoaPods repos

MVP behavior:

- Cache cleanup is medium risk.
- Repo cleanup requires explaining redownload cost.

### Node / pnpm / npm

Included:

- pnpm store
- npm cache
- large `node_modules` detection

MVP behavior:

- `pnpm store prune` is preferred over deleting the store directory.
- npm cache cleanup is medium risk.
- `node_modules` is never automatically deleted in MVP.

### HarmonyOS / DevEco

Included:

- ohpm cache
- hvigor cache
- DevEco Studio cache/build directories where discoverable
- OHOS SDK size detection

MVP behavior:

- Cache directories can be suggested when known.
- SDK directories are manual review only.
- Unknown OHOS/DevEco directories are reported as unsupported cache rules.

### Manual-Only Analysis

Included as analysis, not automatic cleanup:

- virtual machines
- Docker volumes
- project source directories
- large application data directories such as Notion, Lark, browsers, or IDE workspaces

## 7. Risk Model

### Low Risk

Rebuildable cache. Deletion may cause slower first launch or first build, but should not require network access or SDK reinstall.

Examples:

- Xcode DerivedData
- Xcode module cache
- unavailable simulators
- Gradle daemon data

### Medium Risk

Rebuildable data that may require network redownload, dependency restore, package reindexing, or longer build recovery.

Examples:

- Gradle caches
- Dart pub cache
- CocoaPods cache/repos
- pnpm store via prune
- npm cache

### High Risk

Toolchain data that may be required by active projects, current SDK versions, current devices, or offline development.

Examples:

- Android NDK versions
- Android system images
- iOS DeviceSupport
- FVM SDK versions
- simulator device data

### Manual Only

Large data that is not safely classifiable as developer cache.

Examples:

- VMware virtual machines
- Docker volumes
- source projects
- user documents
- app databases

## 8. Exception Catalog

The app must enumerate exceptions instead of silently falling back.

### PermissionDenied

The app cannot read, scan, or delete a path due to macOS permissions.

Required output:

- path
- operation
- suggested permission fix

### PathNotFound

Expected path does not exist.

Required output:

- path
- related toolchain
- whether this is normal

### ToolMissing

Required command is unavailable.

Examples:

- `xcrun`
- `fvm`
- `pnpm`
- `ohpm`
- `hvigor`

Required output:

- command
- cleanup rule affected
- fallback behavior

### ToolCommandFailed

A tool command returned a non-zero exit code.

Required output:

- command
- exit code
- stderr
- affected cleanup item

### FileInUse

Directory or file appears to be used by a running app or process.

Required output:

- path
- suspected process if discoverable
- retry recommendation

### ActiveRuntimeProtected

The item is currently active and cannot be deleted.

Examples:

- booted simulator
- selected FVM version
- current project SDK

Required output:

- protected item
- reason

### SizeChangedDuringScan

Size changed between scan and execution.

Required output:

- previous size
- current size
- whether user confirmation is required again

### PartialCleanup

Some files were deleted and some failed.

Required output:

- successful size estimate
- failed paths
- exception per failed path

### NetworkRebuildRisk

Cleanup is possible, but rebuilding may require network access.

Required output:

- package manager/tool
- cache path
- likely redownload action

### UnsupportedCacheRule

The scanner found a large directory but has no safe rule for it.

Required output:

- path
- size
- reason it is not automatically cleanable

## 9. Core User Flow

1. User launches app.
2. App performs a read-only scan.
3. App groups results by developer stack.
4. App labels each item with size, risk, explanation, and default selection state.
5. User reviews items and optionally opens details.
6. User generates cleanup plan.
7. App shows exact actions and expected impact.
8. User confirms execution.
9. App executes item-by-item.
10. App shows release estimate, successes, skipped items, failures, and exceptions.

## 10. Non-Goals

The MVP will not:

- promise full system cleanup
- delete arbitrary large folders
- delete user projects automatically
- delete virtual machines automatically
- delete Docker volumes automatically
- bypass macOS permission controls
- hide command failures
- optimize app launch agents or system services

## 11. Success Metrics

### Functional Metrics

- Detects at least 80% of common developer cache categories on target machines.
- Recovers 30GB or more on cache-heavy developer machines without breaking active toolchains.
- Provides an exception reason for every failed cleanup item.

### User Experience Metrics

- User can understand why an item is safe or risky before selecting it.
- User can complete low-risk cleanup in under three minutes.
- User can export or copy the cleanup report for troubleshooting.

## 12. Open Questions

- Should the MVP be a full window app only, or include a menu bar companion?
- Should the app support scheduled monitoring in v1, or keep it manual?
- Should project-aware scanning require selecting project roots, or infer them from recent IDE/project folders?
- Should Docker be in MVP as manual-only analysis or postponed entirely?
