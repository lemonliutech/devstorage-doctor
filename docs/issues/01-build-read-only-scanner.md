# Build read-only cache scanner

## Goal

Implement the first scanner that measures developer cache directories without deleting anything.

## Scope

- Xcode / iOS Simulator
- Android / Gradle
- Flutter / Dart / FVM
- CocoaPods
- Node / pnpm / npm
- HarmonyOS / DevEco candidates

## Acceptance Criteria

- Scanner returns path, size, toolchain, and detection status.
- Missing paths are reported as `PathNotFound`, not errors.
- Permission failures are reported as `PermissionDenied`.
- No cleanup action is executed.
