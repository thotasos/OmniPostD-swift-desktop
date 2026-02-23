# OmniPostD Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Deliver a native macOS OmniPost desktop replica with local persistence, parity workflows, tests, and root-level `.app` bundle.

**Architecture:** SwiftUI UI shell with SwiftData persistence and service-oriented domain layer that simulates account connections and social publishing attempts while preserving OmniPost semantics.

**Tech Stack:** Swift 5.10+, SwiftUI, SwiftData, XCTest, xcodebuild.

---

### Task 1: Project scaffold
**Files:**
- Create: `Package.swift`, `Sources/OmniPostDApp/*`, `Tests/OmniPostDTests/*`

1. Create macOS SwiftUI executable package skeleton.
2. Add domain, service, viewmodel, and view folders.
3. Add test target.
4. Commit.

### Task 2: Domain and catalog (TDD)
**Files:**
- Create: `Sources/OmniPostDApp/Domain/Platform.swift`
- Create: `Tests/OmniPostDTests/PlatformCatalogTests.swift`

1. Write failing tests for platform counts, limits, and metadata.
2. Run tests (RED).
3. Implement minimal catalog.
4. Run tests (GREEN).
5. Commit.

### Task 3: Publishing logic (TDD)
**Files:**
- Create: `Sources/OmniPostDApp/Services/PublishingService.swift`
- Create: `Tests/OmniPostDTests/PublishingServiceTests.swift`

1. Write failing tests for publish outcomes, queue status, retry behavior.
2. Run tests (RED).
3. Implement service.
4. Run tests (GREEN).
5. Commit.

### Task 4: Persistence models and store
**Files:**
- Create: `Sources/OmniPostDApp/Models/*.swift`
- Create: `Sources/OmniPostDApp/Persistence/PersistenceController.swift`

1. Implement SwiftData models matching required entities.
2. Wire persistence container.
3. Add seeding/utility methods.
4. Commit.

### Task 5: App UI + navigation
**Files:**
- Create: `Sources/OmniPostDApp/Views/*`
- Create: `Sources/OmniPostDApp/ViewModels/*`
- Create: `Sources/OmniPostDApp/OmniPostDApp.swift`

1. Implement sidebar navigation and four primary pages.
2. Build composer with media attach, platform selection, overrides.
3. Build dashboard, queue, settings parity views.
4. Apply premium visual system and adaptive layout.
5. Commit.

### Task 6: Verification and packaging
**Files:**
- Create: `scripts/build_app.sh`, `README.md`

1. Run full test suite and build commands.
2. Produce `OmniPostD.app` at repository root.
3. Document run/build instructions.
4. Git init, commit history, push attempt.

