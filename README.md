# OmniPostD (macOS Desktop)

Native Swift desktop replica of OmniPost web workflows (Dashboard, Composer, Queue, Settings) with local persistence and standalone OAuth account connection.

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

## Standalone OAuth Connections
1. Create/edit: `~/Library/Application Support/OmniPostD/oauth_credentials.json`.
2. Add `clientID` and `clientSecret` for each provider.
3. Configure provider redirect URI to: `http://localhost:8765/callback`.
4. In app, click `Connect`.
5. Complete consent in browser.
6. Copy final redirected URL and paste it in the app's completion sheet.

## Notes
- Account connection is standalone in desktop app (no Gemini backend required).
- Instagram uses Facebook scopes. Discord webhook and Tumblr OAuth1 remain limited.
- Publishing actions are simulated in desktop app while preserving OmniPost flow and statuses.
