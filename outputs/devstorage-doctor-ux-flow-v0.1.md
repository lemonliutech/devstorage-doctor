# DevStorage Doctor UX Flow v0.1

## 1. UX Goal

DevStorage Doctor should make development storage cleanup feel explainable, controlled, and reversible where possible.

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
- Package Outputs
- Node / pnpm / npm
- CocoaPods
- HarmonyOS / DevEco
- Manual Review

Flutter group note:

- The Flutter / Dart / FVM group should include a project-roots section.
- Users can add workspace folders to scan Flutter project artifacts.
- The app should show project-level build artifacts separately from global Dart and FVM caches.
- Package outputs should be shown as a separate subgroup so users can distinguish temporary test artifacts from dependency/build caches.

Empty state:

- If no development storage items are found, show detected toolchains and explain that no safe cleanup rule matched.

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
- rebuild/redownload/regeneration cost
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
This cleanup may require package managers to download dependencies again or projects to regenerate build outputs. It will not delete source projects, active simulators, current FVM SDKs, or package outputs outside folders you marked as disposable.
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
- Flutter project roots

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

## 7. Core Components

### Disk Pressure Summary

Purpose:

Show the user's current disk situation before listing cleanup details.

Fields:

- free space
- used space
- total disk size
- low-risk recoverable
- medium-risk recoverable
- manual-review data
- package-output data
- last scan time

States:

- healthy
- low disk space
- critically low disk space
- scan unavailable

### Development Storage Item Row

Purpose:

Represent one detected cache, dependency store, build artifact, or package output in a dense but understandable row.

Fields:

- checkbox or protected indicator
- display name
- toolchain icon/name
- size
- risk badge
- short impact sentence
- disclosure control

Expanded fields:

- path
- generated by
- cleanup method
- rebuild behavior
- possible exceptions
- command preview
- protection reason

### Risk Badge

Labels:

- Low Risk
- Medium Risk
- High Risk
- Manual Review
- Protected
- Unsupported

Rules:

- Do not use color alone to communicate risk.
- Pair badge text with explanation in item details.
- Reserve warning color for high-risk and failure states.

### Cleanup Plan Panel

Purpose:

Keep selected cleanup actions visible while the user reviews scan results.

Fields:

- selected count
- expected recovery
- risk breakdown
- protected excluded count
- next action

States:

- empty
- ready
- needs confirmation
- blocked by exception

### Exception Row

Purpose:

Make scan and cleanup failures readable.

Fields:

- exception name
- affected path
- operation
- short cause
- suggested next action
- copy detail action

## 8. Content Guidelines

### Naming

Use plain developer language:

- "Xcode DerivedData"
- "Gradle caches"
- "FVM SDK versions"
- "Unavailable simulators"
- "Manual review"

Avoid vague labels:

- "Junk"
- "System garbage"
- "Hidden trash"
- "Dangerous files"

### Risk Copy

Low-risk example:

```text
Can be rebuilt automatically. The next build may be slower.
```

Medium-risk example:

```text
Can be rebuilt, but dependencies may need to be downloaded again.
```

Package-output manual-review example:

```text
Generated package output. Keep it if it was used for QA, upload, symbolication, or release history.
```

High-risk example:

```text
May be required by active projects or offline builds. Review before cleanup.
```

Protected example:

```text
Protected because this simulator is currently booted.
```

Unsupported example:

```text
Large directory found, but DevStorage Doctor does not have a safe cleanup rule for it.
```

### Confirmation Copy

Confirmation should be specific:

```text
This cleanup will remove 3 low-risk caches and 1 medium-risk build artifact. It will not delete source projects, active simulators, current FVM SDKs, or package outputs outside disposable folders.
```

Avoid generic claims:

```text
Your Mac will be optimized.
```

## 9. Screen-Level Wireframe Notes

### Overview Layout

Preferred layout:

```text
┌ Sidebar ┬ Disk summary + grouped cache list ┬ Cleanup plan ┐
│ Groups  │ Results table                     │ Selection    │
│ Reports │ Expandable rows                   │ Risk summary │
│ Settings│ Manual-review section             │ CTA          │
└─────────┴───────────────────────────────────┴──────────────┘
```

Reasoning:

- Developers can scan dense information quickly.
- Plan remains visible without forcing a wizard.
- Detail disclosure prevents the first screen from becoming overwhelming.

### Cleanup Plan Drawer

The plan can be a right panel in the MVP. If the window is narrow, it can become a bottom drawer.

Minimum width behavior:

- sidebar collapses to icons
- plan panel becomes bottom drawer
- item rows keep name, size, risk, and selection visible

### Report View

The report should feel like a build log summary, not a celebration screen.

Recommended sections:

- Space recovered
- Completed actions
- Skipped protected items
- Exceptions
- Manual review suggestions
- Copy report

## 10. Accessibility Requirements

- All risk states must have text labels.
- Checkboxes must be keyboard reachable.
- Disclosure rows must support keyboard expansion.
- Command previews must be selectable/copyable.
- Report content must be readable by VoiceOver.
- Color contrast should meet WCAG AA where applicable.

## 11. MVP UX Acceptance Criteria

- User can run a scan without deleting anything.
- User can see grouped cache results by developer stack.
- Every cleanup item has a path, size, risk, and impact explanation.
- User can generate a cleanup plan before execution.
- User can review command-level actions before execution.
- User can see protected and skipped items.
- Cleanup failures are displayed with named exceptions.
- Final report can be copied.

## 12. Future UX Ideas

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
