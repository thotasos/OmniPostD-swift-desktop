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

## Notes
- This build is local-first and does not call the original web backend.
- Account connections and publishing are simulated while preserving OmniPost flow and statuses.
