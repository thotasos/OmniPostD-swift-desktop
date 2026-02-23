# OmniPostD Desktop Replica Design

**Date:** 2026-02-23  
**Status:** Approved by default execution policy (user unavailable for iterative confirmation)  
**Source of Truth Reviewed:** `/Users/thotas/Development/Gemini` (read-only)

## 1. Objective
Build a macOS desktop app in `/Users/thotas/Development/Codex/OmniPostD` that replicates OmniPost web app workflows and data semantics, with an Apple-grade premium UX, without changing any files in `/Users/thotas/Development/Gemini`.

## 2. Functional Requirements
- Dashboard: connected accounts summary, quick connect/disconnect, recent posts.
- Composer: unified content editor, media attachments, platform selection, platform-specific overrides, post now, queue.
- Queue: historical posts with per-platform attempt badges, retry for failed attempts.
- Settings: account inventory and connect/disconnect controls for all platforms.
- Platform catalog: 11 platforms with character limits and content type metadata.
- Local persistence: data survives app restart.

## 3. Non-Functional Requirements
- Native macOS desktop app built in Swift.
- App bundle (`.app`) generated at repository root and launchable by double click.
- Smooth animations, responsive window resizing, keyboard-friendly interactions.
- Deterministic behavior without requiring external backend services.

## 4. Product Decisions (PM)
- Decision: local-first architecture.
- Why: guarantees immediate usability and packaging with no external dependency.
- Tradeoff: OAuth and real social publishing are simulated in v1.

- Decision: preserve web information architecture (Dashboard, Composer, Queue, Settings).
- Why: parity minimizes cognitive change and migration cost.

- Decision: model real publishing as simulation service with failure injection heuristics.
- Why: allows meaningful queue/retry UX and testability.

## 5. UX Direction (Expert)
- Visual language: clean, vibrant, minimalist, premium macOS aesthetic.
- Surfaces: subtle translucency, rounded cards, depth via shadows and blur.
- Colors: restrained neutral base plus platform accents.
- Motion: spring-based transitions for selection, publish progress, list updates.
- Responsiveness: adaptive stacks and grids for narrow/wide windows.
- Accessibility: high contrast labels, clear status affordances, large click targets.

## 6. High-Level Architecture
- `OmniPostDApp`: app entry + root navigation.
- `PersistenceController`: SwiftData container setup.
- Domain models: `SocialAccount`, `PostRecord`, `PostAttemptRecord`, `MediaItemRecord`.
- Services:
  - `PlatformCatalogService` (platform capabilities)
  - `AccountService` (connect/disconnect simulated OAuth)
  - `PublishingService` (post/queue/retry orchestration)
  - `MediaService` (import and local file references)
- ViewModels:
  - `DashboardViewModel`
  - `ComposerViewModel`
  - `QueueViewModel`
  - `SettingsViewModel`

## 7. Data Flow
1. User connects platform in Dashboard/Settings.
2. AccountService creates active account entry.
3. Composer builds `PostRecord` with target platforms and overrides.
4. Publish action creates `PostAttemptRecord` entries per target platform.
5. PublishingService marks each attempt success/fail, updates post status.
6. Queue view reflects aggregate and per-platform statuses; retry re-runs failed attempts.

## 8. Error Handling
- Validation errors: no platform selected, empty content/media constraints.
- Publish failures: captured at attempt level with readable messages.
- Media import errors: surfaced as non-blocking alerts.

## 9. Testing Strategy
- Unit tests for publishing rules and status transitions.
- Unit tests for character-limit validation and override precedence.
- Smoke test app build and launch command.

## 10. Decision Log
- Ambiguity: backend coupling vs standalone.
  - Resolution: standalone local-first.
- Ambiguity: OAuth realism.
  - Resolution: simulated connect flow with account metadata.
- Ambiguity: push destination.
  - Resolution: initialize repo and attempt push; if no remote/auth, report exact blocker.

## 11. Out of Scope (v1)
- Real OAuth handshakes with platform credentials.
- Real API publishing to social networks.
- Multi-user auth and cloud sync.
