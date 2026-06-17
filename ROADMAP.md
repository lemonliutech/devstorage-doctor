# DevStorage Doctor Roadmap

## v0.1 Product Design

- [x] Define product positioning
- [x] Define target users and jobs to be done
- [x] Define MVP cache categories
- [x] Define risk model
- [x] Define exception catalog
- [x] Define UX flow

## v0.2 Prototype

- [ ] Choose macOS implementation stack
- [ ] Build read-only scanner prototype
- [ ] Detect Xcode and iOS Simulator cache sizes
- [ ] Detect Android and Gradle cache sizes
- [ ] Detect Flutter, Dart, and FVM cache sizes
- [ ] Detect Flutter project build artifacts inside selected project roots
- [ ] Detect temporary mobile package outputs inside selected project roots
- [ ] Detect Node, pnpm, npm, and CocoaPods cache sizes
- [ ] Detect HarmonyOS / DevEco cache candidates
- [ ] Produce grouped scan report

## v0.3 Cleanup Planning

- [ ] Add risk classification engine
- [ ] Add protected item detection
- [ ] Generate cleanup plan without execution
- [ ] Show command previews
- [ ] Add copyable report output

## v0.4 Controlled Cleanup

- [ ] Execute low-risk cleanup actions
- [ ] Execute medium-risk cleanup after confirmation
- [ ] Protect high-risk and manual-only items
- [ ] Record success, skipped, partial, and failed states
- [ ] Display named exceptions

## v1.0 Candidate

- [ ] Native macOS UI
- [ ] Settings for custom scan paths
- [ ] Exportable cleanup reports
- [ ] Project-aware scanning
- [ ] Menu bar disk pressure monitor
- [ ] Release packaging

## v1.x Expansion Tracks

- [ ] Homebrew and package-manager cache rule pack
- [ ] IDE cache rule pack for VS Code and JetBrains tools
- [ ] Language ecosystem rule packs for Go, Rust, Python, Ruby, Java, SwiftPM, Yarn, and Bun
- [ ] Package-output analysis for mobile release/test artifacts
- [ ] Container/runtime analysis for Docker, Colima, Lima, and local Kubernetes
- [ ] Build-system cache rules for Bazel, CMake, ccache, Metro, Watchman, Unity, and Unreal
- [ ] Project-aware protection based on repository manifests and lockfiles
- [ ] Declarative rule-pack system for team-specific cleanup rules
- [ ] Menu bar monitoring and scheduled read-only reports
