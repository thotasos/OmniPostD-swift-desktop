# OmniPostD (macOS Desktop)

Native Swift desktop replica of OmniPost web workflows (Dashboard, Composer, Queue, Settings) with local persistence and simulated publishing.

## Requirements
- macOS 14+
- Xcode 26+ / Swift 6.2+

## Run Tests
```bash
swift test
```

## Build CLI Executable
```bash
swift build -c release
```

## Build Clickable App Bundle
```bash
./scripts/build_app.sh
```

This generates `OmniPostD.app` at repository root.

## Real OAuth Connections
1. Start the Gemini backend at `http://localhost:8000`.
2. In OmniPostD, click `Connect` for a platform.
3. Browser opens the platform OAuth consent flow.
4. Complete consent in browser.
5. Back in app, click `Refresh Accounts` (Dashboard or Settings).

## Notes
- Account connection now uses backend OAuth endpoints (`/auth/*`) and account sync (`/api/accounts`).
- Publishing actions are still simulated in desktop app while preserving OmniPost flow and statuses.
