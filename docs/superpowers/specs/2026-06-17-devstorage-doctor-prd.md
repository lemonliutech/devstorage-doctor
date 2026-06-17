# DevStorage Doctor PRD v0.1

## 1. Product Summary

**Product name:** DevStorage Doctor

**Theme:** macOS development storage cleanup tool for cross-platform developers

**Positioning:** A macOS development storage diagnostic and cleanup tool for cross-platform mobile developers. It helps users understand disk usage, classify cleanup risk, generate an auditable cleanup plan, and safely recover disk space.

DevStorage Doctor is not a generic "junk cleaner". It focuses on reproducible development storage that is large, confusing, and often safe to rebuild or regenerate, but risky to delete blindly.

The product scope includes caches, dependency stores, installed SDK/runtime artifacts, project build outputs, and temporary packaging outputs. This is important because developers often create app packages only to test an output, then never manually remove the generated artifacts.

## 2. Problem

Multi-platform developers routinely accumulate tens or hundreds of gigabytes of development storage across:

- Xcode and iOS Simulator
- Android SDK, Emulator, and Gradle
- Flutter, Dart, and FVM
- CocoaPods
- Node, npm, and pnpm
- HarmonyOS, DevEco, ohpm, and hvigor
- project build outputs and temporary package outputs
- Docker, virtual machines, and large project folders

When disk space is nearly full, developers know that some of this data is disposable, but they often do not know:

- what each directory is for
- whether deletion will break current projects
- whether the data can be regenerated
- how much rebuild or redownload cost deletion causes
- whether a package output is still useful or was only created for a quick test
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

When my Mac disk is almost full, I want to know which development files are safe to remove, so that I can recover space without breaking my current projects.

When I see a huge directory, I want to understand what produced it and whether it is rebuildable, so that I do not delete important project or SDK data by mistake.

When cleanup fails, I want to see the exact exception and suggested fix, so that I can resolve the real problem instead of repeatedly trying fallback deletes.

## 5. Product Principles

1. **Explain before clean**
   Every cleanup item must explain what it is, why it exists, what deletes it, and what happens afterward.

2. **Risk-first selection**
   Low-risk items may be selected by default. Medium-risk items require explicit user selection. High-risk and non-cleanable items are suggestions only.

3. **Developer-context aware**
   The app should detect active projects, booted simulators, current FVM versions, installed SDKs, package managers, generated build outputs, package outputs, and tool availability.

4. **Auditable execution**
   The app generates a cleanup plan before execution and records success, skipped items, failures, and exceptions after execution.

5. **No destructive guessing**
   If the app cannot classify a directory safely, it must not delete it automatically.

## 6. Product Vocabulary

Use consistent English product language across the app and documentation.

### Product Category

**macOS development storage cleanup tool for cross-platform developers**

### Primary Terms

- **Scan:** Read-only disk analysis. A scan never deletes files.
- **Development Storage Item:** A detected directory, file group, or tool-managed store that may be cleanable or worth manual review.
- **Cache Item:** A rebuildable cache produced by a tool, package manager, IDE, simulator, or build system.
- **Dependency Store:** Downloaded or installed dependencies that can usually be restored but may require network access.
- **Build Artifact:** Generated project output such as intermediate build directories, native build products, and compiled assets.
- **Package Output:** Generated distributable/test artifact such as `.ipa`, `.apk`, `.aab`, `.hap`, `.app`, `.xcarchive`, `.dSYM`, or exported release folders.
- **Cleanup Rule:** The app's known strategy for analyzing and optionally cleaning a development storage item.
- **Cleanup Plan:** A user-reviewable list of actions generated from selected development storage items.
- **Protected Item:** A detected item that the app refuses to delete because it appears active or risky.
- **Manual Review:** A large item that is useful to surface but outside automatic cleanup.
- **Exception:** A named scan or cleanup failure with path, operation, cause, and suggested next step.

### Product Voice

The product should avoid words like "junk", "trash", "boost", or "deep clean". Preferred language:

- "recover disk space"
- "cleanup plan"
- "rebuild cost"
- "regeneration cost"
- "package output"
- "protected because active"
- "manual review required"
- "cleanup failed with exception"

## 7. MVP Scope

### Xcode / iOS

Included:

- `~/Library/Developer/Xcode/DerivedData`
- `~/Library/Developer/Xcode/NewDerivedData`
- Xcode module caches
- unavailable iOS Simulator devices via `xcrun simctl delete unavailable`
- iOS Simulator device data size analysis
- `~/Library/Developer/Xcode/iOS DeviceSupport` analysis
- `.xcarchive` analysis in configured archive locations
- `.dSYM` analysis in configured output locations
- generated `.ipa` analysis in selected project/output directories

MVP behavior:

- DerivedData and unavailable simulators can be low-risk cleanup candidates.
- Booted simulators must be protected.
- DeviceSupport should default to manual review because it may be needed for physical-device debugging.
- Archives, dSYMs, and IPA files default to manual review because they may be release evidence or debugging artifacts.
- The app may suggest package outputs as likely disposable only when they are inside explicitly configured test-output directories.

### Android / Gradle

Included:

- `~/.gradle/caches`
- `~/.gradle/daemon`
- `~/.gradle/wrapper`
- Android SDK size analysis
- Android NDK versions
- Android system images
- Emulator images
- generated `.apk` and `.aab` files in selected project/output directories
- Android project build outputs in selected project roots

MVP behavior:

- Gradle daemon cleanup is low risk.
- Gradle caches are medium risk because dependencies may need to redownload.
- NDK and system image cleanup require manual selection.
- APK and AAB outputs default to manual review unless they are in a configured disposable test-output directory.

### Flutter / Dart / FVM

Included:

- `~/.pub-cache/hosted`
- `~/.pub-cache/git`
- FVM versions
- Flutter SDK cache analysis
- Flutter project discovery in user-selected project roots
- Flutter project build artifact detection
- Flutter package and native build artifact size analysis

MVP behavior:

- Pub cache cleanup is medium risk.
- Current FVM SDK versions must be protected.
- Unused FVM versions can be suggested, but not selected by default.
- Flutter project artifacts are scanned only inside explicit project roots or user-configured workspace directories.
- The app should not crawl the whole disk looking for Flutter projects in MVP.
- Flutter project artifact cleanup is medium risk by default because it may remove build outputs and trigger full rebuilds.

Flutter project artifact candidates:

- `<project>/build/`
- `<project>/.dart_tool/`
- `<project>/.packages` when present in older projects
- `<project>/ios/Pods/`
- `<project>/ios/.symlinks/`
- `<project>/ios/Flutter/Flutter.framework` when generated
- `<project>/ios/Flutter/Flutter.podspec` when generated
- `<project>/android/.gradle/`
- `<project>/android/build/`
- `<project>/android/app/build/`
- `<project>/ohos/build/`
- `<project>/harmonyos/build/` when present
- generated release artifacts under configured output directories
- generated `.apk`, `.aab`, `.ipa`, `.app`, `.hap`, and exported release folders

Protected Flutter project items:

- source files
- `pubspec.yaml`
- lockfiles
- platform source directories themselves
- signing files
- keystores
- provisioning profiles
- manually configured output directories unless explicitly marked as disposable

### Project Package Outputs

Included:

- generated `.ipa`
- generated `.apk`
- generated `.aab`
- generated `.hap`
- generated `.app`
- generated `.xcarchive`
- generated `.dSYM`
- release/export folders inside selected project roots
- custom package output directories configured by the user

MVP behavior:

- Package outputs are scanned and explained, but not selected by default.
- Package outputs default to manual review because they may be needed for QA, release upload, crash symbolication, or audit history.
- Users can mark a folder as a disposable test-output directory. Only then can package outputs inside it become medium-risk selectable cleanup candidates.
- The app should detect likely test outputs using path context and age, but should not rely on filename heuristics alone.
- The app must never delete signing assets, provisioning profiles, keystores, or release metadata as part of package-output cleanup.

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
- package-manager dependency stores
- project-level dependency directories in selected project roots

MVP behavior:

- `pnpm store prune` is preferred over deleting the store directory.
- npm cache cleanup is medium risk.
- `node_modules` is never automatically deleted in MVP.
- Project-level dependency directories are detected for visibility but default to manual review unless a project-specific rule marks them safe.

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
- release archives and package outputs outside disposable test-output directories
- large application data directories such as Notion, Lark, browsers, or IDE workspaces

## 8. Scope Completeness Assessment

The MVP scope is sufficient for the first target segment: cross-platform mobile developers using Xcode, Android, Flutter, Node, CocoaPods, and HarmonyOS tooling.

It is not yet complete for the broader product category, "macOS development storage cleanup tool for cross-platform developers." The broader category should eventually include container runtimes, IDE caches, package managers, language ecosystems, dependency directories, package outputs, and build-system artifacts beyond mobile app development.

### Covered Well In MVP

- iOS and Xcode cache pressure
- iOS Simulator cleanup and unavailable device detection
- Android SDK and Gradle cache pressure
- Flutter, Dart, and FVM cache pressure
- Flutter and mobile package-output pressure
- CocoaPods cache and repo pressure
- Node package cache pressure through npm and pnpm
- HarmonyOS / DevEco early support
- Manual review for source projects, virtual machines, Docker volumes, and large app data

### Partially Covered

- Docker is only manual-review in MVP, not cache-aware.
- `node_modules` is detected but never automatically cleaned.
- Package outputs are detected but default to manual review unless they live in disposable test-output folders.
- Android SDK cleanup is size-aware but not yet version-usage-aware.
- HarmonyOS / DevEco rules are expected to start conservative because directory layouts may vary.
- Project-aware scanning exists as a future direction but is not required for the first scanner.

### Missing From MVP

These are intentionally outside MVP but important for later versions:

- Homebrew caches and old downloads
- Docker, Colima, Lima, and container image/build caches
- JetBrains IDE caches
- VS Code extension caches and workspace storage
- Swift Package Manager caches
- Maven, Gradle wrapper distributions, and Kotlin daemon caches beyond basic Gradle directories
- Python pip, uv, poetry, conda, and virtual environment analysis
- Ruby Bundler and CocoaPods derived integration artifacts
- Rust Cargo registry and target directories
- Go module cache and build cache
- Bun and Yarn caches
- Bazel, Buck, CMake, ccache, and other build-system caches
- React Native specific caches, Metro cache, Watchman state
- Unity, Unreal, and game-development build caches
- AI development tool caches, model downloads, and local sandbox/runtime caches
- Time Machine local snapshots and APFS purgeable-space explanation

### Scope Principle

The product should not try to support every storage type by adding one-off delete commands. Each new area should be added only when the app can provide:

- detection confidence
- size measurement
- risk classification
- active-use protection
- rebuild, redownload, or regeneration explanation
- named exception handling
- a safe default selection state

## 9. Expansion Strategy

Expansion should happen in layers, from highest-confidence reproducible development storage to broader ecosystem support.

### Phase 1: Mobile Cross-Platform Core

Goal:

Ship a reliable tool for the original target user.

Includes:

- Xcode / iOS
- Android / Gradle
- Flutter / Dart / FVM
- CocoaPods
- Node npm/pnpm
- HarmonyOS / DevEco conservative detection
- project build artifact and package-output analysis
- manual-only large directory analysis

Why this phase first:

These categories match the user's real disk-pressure evidence and create a differentiated product compared with Xcode-only cleaners.

### Phase 2: Developer Ecosystem Expansion

Goal:

Cover common macOS development storage beyond mobile app projects.

Candidate additions:

- Homebrew cache cleanup
- Swift Package Manager
- VS Code and JetBrains caches
- Go, Rust, Python, Ruby, Java/Maven cache families
- Yarn and Bun caches
- CMake, ccache, and other local build caches
- common package and release output directories

Design requirement:

Each ecosystem should enter as a rule pack with explicit risk labels and rebuild-cost copy, not as a hard-coded UI special case.

### Phase 3: Container And Runtime Expansion

Goal:

Help users understand container and runtime disk usage without accidentally deleting critical state.

Candidate additions:

- Docker image, build cache, and volume analysis
- Colima and Lima disk image analysis
- Kubernetes local cluster cache analysis
- VM image detection and migration suggestions

MVP stance:

Docker volumes and VM images remain manual-only until the app can distinguish disposable build cache from user data.

### Phase 4: Project-Aware Cleanup

Goal:

Protect active development environments by scanning project roots and inferring dependencies.

Project signals:

- `.fvmrc`
- `pubspec.yaml`
- `ios/Podfile`
- `android/gradle`
- `package.json`
- `pnpm-lock.yaml`
- `oh-package.json5`
- `Package.swift`
- `go.mod`
- `Cargo.toml`
- `pyproject.toml`

Benefits:

- protect active SDK versions
- identify stale build directories
- identify test-only package outputs
- distinguish current package caches from unused versions
- make medium-risk cleanup more trustworthy

### Phase 5: Rule Packs And Extensibility

Goal:

Allow advanced users and teams to add or disable cleanup rules without changing core app code.

Rule pack requirements:

- declarative paths and detection commands
- risk level
- cleanup command or method
- active-use checks
- exception mapping
- dry-run support
- versioned rule metadata

Potential format:

```yaml
id: homebrew-cache
name: Homebrew Cache
group: Package Managers
risk: Medium
detect:
  paths:
    - ~/Library/Caches/Homebrew
clean:
  command: brew cleanup --prune=all
exceptions:
  - ToolMissing
  - ToolCommandFailed
  - PermissionDenied
```

### Phase 6: Monitoring And Automation

Goal:

Move from one-off cleanup to ongoing developer-environment maintenance.

Potential features:

- menu bar disk pressure monitor
- cache growth since last scan
- weekly read-only report
- team-shared rule packs
- cleanup history and trends
- optional reminders, not automatic deletion

Automation rule:

The app may automate scanning, but cleanup should remain user-confirmed unless a user explicitly enables a narrow low-risk rule.

## 10. Risk Model

### Low Risk

Rebuildable or regeneratable storage. Deletion may cause slower first launch or first build, but should not require network access, SDK reinstall, release re-export, or manual reconstruction.

Examples:

- Xcode DerivedData
- Xcode module cache
- unavailable simulators
- Gradle daemon data

### Medium Risk

Rebuildable or regeneratable data that may require network redownload, dependency restore, package reindexing, full rebuild, or re-exporting a test package.

Examples:

- Gradle caches
- Dart pub cache
- CocoaPods cache/repos
- pnpm store via prune
- npm cache
- package outputs inside folders explicitly marked as disposable test-output directories

### High Risk

Toolchain data or generated outputs that may be required by active projects, current SDK versions, current devices, offline development, QA, release upload, crash symbolication, or audit history.

Examples:

- Android NDK versions
- Android system images
- iOS DeviceSupport
- FVM SDK versions
- simulator device data
- release archives
- dSYM files
- package outputs outside disposable test-output directories

### Manual Only

Large data that is not safely classifiable as disposable development storage.

Examples:

- VMware virtual machines
- Docker volumes
- source projects
- user documents
- app databases
- release evidence and package archives outside configured cleanup rules

## 11. Exception Catalog

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

## 12. Core User Flow

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

## 13. User Stories

### US-1: Understand Disk Pressure

As a cross-platform developer, I want to see how much disk space is used by developer tooling, dependencies, build artifacts, and package outputs, so that I can decide whether cleanup is worth doing.

Acceptance criteria:

- The overview shows total available disk space.
- The overview separates caches, dependencies, build artifacts, package outputs, and manual-only large data.
- The overview shows low-risk, medium-risk, and manual-review totals.

### US-2: Clean Low-Risk Caches

As a developer, I want low-risk caches to be selected by default, so that I can quickly recover space without reading every item.

Acceptance criteria:

- Low-risk items are selected by default.
- The app explains that deletion may slow the next build or launch.
- The cleanup plan can be reviewed before execution.

### US-3: Protect Active Toolchains

As a developer working on active projects, I want the app to protect current SDKs and running simulators, so that cleanup does not break my current workflow.

Acceptance criteria:

- Booted simulators are not selected.
- Current FVM versions are not selected.
- Unknown SDK directories are manual review only.
- Protected items show the reason they are protected.

### US-4: Review Medium-Risk Cleanup

As a developer, I want medium-risk items to be opt-in, so that I do not accidentally trigger long redownloads.

Acceptance criteria:

- Medium-risk items are unselected by default.
- Each item shows likely rebuild or redownload cost.
- Confirmation mentions network or dependency restore requirements.

### US-5: Diagnose Failed Cleanup

As a developer, I want cleanup failures to be named and actionable, so that I can resolve permission, process, package-output, or dependency issues.

Acceptance criteria:

- Every failed scan or cleanup item has an exception type.
- The report includes path, operation, and suggested next action.
- Partial cleanup is shown explicitly.

## 14. Scanner Rule Taxonomy

Each cleanup rule should be modeled as data, not hard-coded only in UI.

Rule fields:

- id
- display name
- toolchain group
- default paths
- detection method
- cleanup method
- risk level
- default selection state
- active protection checks
- rebuild, redownload, or regeneration cost explanation
- possible exceptions

Example:

```text
id: xcode-derived-data
displayName: Xcode DerivedData
toolchain: Xcode / iOS
paths:
  - ~/Library/Developer/Xcode/DerivedData
  - ~/Library/Developer/Xcode/NewDerivedData
risk: Low
defaultSelected: true
cleanupMethod: remove directory contents
impact: First Xcode build may be slower.
exceptions: PermissionDenied, FileInUse, PartialCleanup
```

## 15. Privacy And Safety

The app should be local-first.

MVP requirements:

- Do not upload paths, directory names, package names, or scan results.
- Do not collect analytics in MVP.
- Do not require network access for scanning.
- Do not require elevated privileges for normal scan.
- Ask for additional macOS permissions only when a path cannot be read.
- Never delete outside an explicit cleanup rule.

Sensitive path handling:

- Full paths may be displayed locally.
- Exported reports should include full paths by default because they are debugging artifacts.
- A later version may add "redact home directory" for shareable reports.

## 16. MVP Milestones

### Milestone 1: Read-Only Scanner

Goal:

Produce a grouped scan report with paths, sizes, missing-path notices, and permission exceptions.

Exit criteria:

- No deletion is possible.
- Xcode, Simulator, Gradle, Pub, FVM, pnpm, CocoaPods, and manual-only large directories can be measured.
- Project-level build artifacts and package outputs can be measured inside selected project roots.

### Milestone 2: Risk Classification

Goal:

Classify scan results and explain each classification.

Exit criteria:

- Risk badge and explanation exist for every development storage item.
- Protected items are marked and excluded from selection.

### Milestone 3: Cleanup Plan

Goal:

Generate an auditable plan from selected items.

Exit criteria:

- Plan can be copied.
- Plan includes commands or cleanup methods.
- Plan includes exceptions that may occur.

### Milestone 4: Controlled Execution

Goal:

Execute selected low-risk and explicitly confirmed medium-risk cleanup.

Exit criteria:

- Execution is item-by-item.
- Failure of one item does not hide later results.
- Final report includes success, skipped, partial, and failed states.

### Milestone 5: Native macOS MVP

Goal:

Ship a native macOS app shell around scan, plan, execution, and report flows.

Exit criteria:

- The app can be used without terminal commands.
- Final report is copyable.
- Settings support custom scan paths.

## 17. Non-Goals

The MVP will not:

- promise full system cleanup
- delete arbitrary large folders
- delete user projects automatically
- delete virtual machines automatically
- delete Docker volumes automatically
- automatically delete package outputs unless the user has explicitly marked the containing folder as disposable
- delete release archives, dSYMs, or QA artifacts by default
- clean Homebrew, Docker, JetBrains, VS Code, language package managers, or build-system caches in the first release unless a rule is explicitly added
- run scheduled cleanup automatically
- bypass macOS permission controls
- hide command failures
- optimize app launch agents or system services

## 18. Success Metrics

### Functional Metrics

- Detects at least 80% of common developer cache categories on target machines.
- Recovers 30GB or more on cache-heavy developer machines without breaking active toolchains.
- Provides an exception reason for every failed cleanup item.

### User Experience Metrics

- User can understand why an item is safe or risky before selecting it.
- User can complete low-risk cleanup in under three minutes.
- User can export or copy the cleanup report for troubleshooting.

## 19. Open Questions

- Should the MVP be a full window app only, or include a menu bar companion?
- Should the app support scheduled monitoring in v1, or keep it manual?
- Should project-aware scanning require selecting project roots, or infer them from recent IDE/project folders?
- Which expansion pack should come first after mobile cross-platform core: Homebrew/IDE caches, Docker/containers, or language ecosystems?
