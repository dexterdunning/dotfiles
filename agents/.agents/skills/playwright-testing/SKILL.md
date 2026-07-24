---
name: playwright-testing
description: Rippling Playwright testing cheat sheet for login, navigation, waits, and API verification (time-tracking focused). Use when writing or debugging Playwright tests against Rippling.
---

# Playwright Testing — Rippling

## Login

1. Fill email → Continue → fill password → Sign in
2. Wait with `waitForURL('**/dashboard**', { timeout: 30000 })`
3. Sign out: click user menu (top-right avatar) → "Sign out" menuitem. `/sign-out` does not work.

## Navigation

- Time tracking root: `/time-products/dashboard/overview`
- Timeclock: `/time-products/dashboard/my-time/timeclock`
- Use sidebar links to navigate between pages, not direct URLs.

## Waiting

- Never use `waitUntil: 'networkidle'` — SSE streams prevent resolution.
- Use `waitForTimeout(8000)` after full navigations, or `waitForURL` for SPA route changes.

## Verifying API calls

- `browser_network_requests` returns all requests for the full session. Save to file and grep.
- Feature flag changes require full page reload (sometimes two) for LaunchDarkly to propagate.

## Dev server

```bash
source config.prod.dev.sh && wcli start dev  # run in background
# https://localhost.rippling.com:3003/
```
