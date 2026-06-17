# DevCache Doctor UX Flow v0.1

## 1. UX Goal

DevCache Doctor should make developer cache cleanup feel explainable, controlled, and reversible where possible.

The app must avoid the visual language of generic "junk cleaners". It should feel like a professional developer utility: dense, clear, calm, and precise.

Primary UX promise:

> Before anything is deleted, the user can understand what it is, why it is safe or risky, what command will run, and what could fail.

## 2. Navigation Model

Use a full-window macOS app as the MVP.

Recommended structure:

- left sidebar for developer stacks
- main content for scan results
- right-side plan panel or bottom confirmation drawer
- execution report as a dedicated post-cleanup view

MVP should not start with a menu bar-only app. A menu bar companion can be added later for monitoring disk pressure and cache growth.

## 3. Primary Screens

### Screen 1: Scan Overview

Purpose:

Show current disk pressure, total cleanable space, risk distribution, and top cache categories.

Core information:

- total disk size
- used space
- available space
- low-risk recoverable space
- medium-risk recoverable space
- manual-only large data
- last scan time

Primary actions:

- `Scan`
- `Rescan`
- `Generate Cleanup Plan`

Layout:

- top summary strip with disk pressure
- left stack navigation
- center grouped result list
- right plan preview

Example groups:

- Xcode / iOS
- Android / Gradle
- Flutter / Dart / FVM
- Node / pnpm / npm
- CocoaPods
- HarmonyOS / DevEco
- Manual Review

Empty state:

- If no developer caches are found, show detected toolchains and explain that no safe cleanup rule matched.

Error state:

- If scan partially fails, show a warning banner and list scan exceptions in the report area.

### Screen 2: Stack Detail

Purpose:

Let users inspect one development stack deeply.

Core information per cleanup item:

- name
- path
- size
- risk level
- selected state
- why it exists
- deletion impact
- rebuild/redownload cost
- command or cleanup method
- protection reason if unavailable

Item states:

- selected
- unselected
- protected
- unsupported
- failed scan
- manual-only

Primary actions:

- select item
- deselect item
- reveal in Finder
- copy path
- view command

Interaction notes:

- Low-risk items can default to selected.
- Medium-risk items default to unselected.
- High-risk items are selectable only after opening details and acknowledging impact.
- Manual-only items cannot be selected for automatic cleanup.

### Screen 3: Cleanup Plan Drawer

Purpose:

Transform selected items into a clear, auditable plan.

The drawer appears after the user clicks `Generate Cleanup Plan`.

Core information:

- expected recovered space
- selected item count
- risk breakdown
- commands to be run
- tools required
- items skipped and why
- rebuild/network warnings

Primary actions:

- `Copy Plan`
- `Back to Results`
- `Confirm Cleanup`

Plan format:

Each action should show:

- display name
- risk
- path or command
- expected impact
- possible exceptions

Example:

```text
Action: Delete Xcode DerivedData
Path: ~/Library/Developer/Xcode/NewDerivedData
Risk: Low
Impact: First Xcode build may be slower.
Possible exceptions: PermissionDenied, FileInUse, PartialCleanup
```

### Screen 4: Confirmation

Purpose:

Prevent accidental destructive actions.

Confirmation should be proportional to risk:

- Low-risk-only cleanup: one confirmation button.
- Medium-risk cleanup: require visible checkbox acknowledgment.
- High-risk cleanup: require item-level acknowledgment.

Required confirmation content:

- total expected cleanup
- selected risk levels
- number of items
- irreversible or redownload warnings
- protected items excluded

Primary actions:

- `Start Cleanup`
- `Cancel`

Copy guidance:

Use plain text. Avoid alarmist language.

Example:

```text
This cleanup may require package managers to download dependencies again. It will not delete source projects, active simulators, or current FVM SDKs.
```

### Screen 5: Execution Progress

Purpose:

Show cleanup progress item by item.

Core information:

- current action
- progress count
- released space estimate
- live status per item
- failures as they happen

Item execution states:

- pending
- running
- succeeded
- skipped
- failed
- partially cleaned

Behavior:

- A failed item must not stop the whole cleanup unless the failure affects a shared prerequisite.
- The app should continue executing independent items.
- The app should keep a structured log for final report.

### Screen 6: Cleanup Report

Purpose:

Make the result explainable and debuggable.

Core information:

- estimated space released
- successful items
- skipped items
- failed items
- exception catalog
- next suggested actions
- copy/export report action

Primary actions:

- `Copy Report`
- `Reveal Failed Paths`
- `Rescan`
- `Done`

Report sections:

- Summary
- Successes
- Skipped
- Exceptions
- Manual Recommendations

Example exception display:

```text
PermissionDenied
Path: ~/Library/Developer/CoreSimulator/Devices/...
Operation: delete
Suggestion: Close Simulator and grant Full Disk Access if needed.
```

## 4. Interaction Rules

### Selection Defaults

Low risk:

- selected by default
- can be deselected

Medium risk:

- unselected by default
- can be selected after reading impact

High risk:

- unselected
- requires detail expansion and explicit acknowledgment

Manual only:

- cannot be selected
- can be copied, revealed, or added to manual checklist

### Protection Rules

The following must be protected:

- booted simulators
- current FVM SDK for active project
- active Android emulator
- active build directory if a build process is detected
- project source directories
- virtual machines
- unknown large directories

### Detail Disclosure

Each cleanup item should support progressive disclosure:

Collapsed row:

- name
- size
- risk
- short impact
- selected state

Expanded detail:

- path
- generated by
- cleanup method
- rebuild behavior
- exceptions
- command preview

## 5. Information Architecture

### Sidebar

```text
Overview
Xcode / iOS
Android / Gradle
Flutter / Dart / FVM
CocoaPods
Node / pnpm / npm
HarmonyOS / DevEco
Manual Review
Reports
Settings
```

### Settings

MVP settings:

- include medium-risk items in plan by default: off
- protect current project SDKs: on
- show command previews: on
- collect anonymous analytics: off by default or absent in MVP
- custom scan paths

## 6. Visual Direction

Tone:

- professional
- calm
- utility-first
- information-dense
- not playful
- not marketing-like

Avoid:

- oversized hero sections
- one-click-clean drama
- scary red warnings everywhere
- vague "junk" labels
- generic file cleanup metaphors

Use:

- compact tables
- risk badges
- progress states
- disclosure rows
- command preview blocks
- clear status icons
- restrained macOS-native styling

## 7. MVP UX Acceptance Criteria

- User can run a scan without deleting anything.
- User can see grouped cache results by developer stack.
- Every cleanup item has a path, size, risk, and impact explanation.
- User can generate a cleanup plan before execution.
- User can review command-level actions before execution.
- User can see protected and skipped items.
- Cleanup failures are displayed with named exceptions.
- Final report can be copied.

## 8. Future UX Ideas

### Menu Bar Monitor

Shows:

- free disk space
- developer cache growth since last scan
- quick scan shortcut

### Project-Aware Mode

User selects one or more project roots.

The app detects:

- `.fvmrc`
- `pubspec.yaml`
- `ios/Podfile`
- `android/gradle`
- `oh-package.json5`
- `package.json`

Then it protects versions and caches likely needed by those projects.

### Team Report Mode

Export a cleanup diagnosis that can be shared with teammates or support engineers.

Useful for:

- onboarding
- CI/local build debugging
- toolchain migration
