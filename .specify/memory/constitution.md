# AgriPrice Constitution

## Core Principles

### I. On-Device First (NON-NEGOTIABLE)

All user-visible data is persisted on the iPhone via SwiftData. There is **no backend** in v1 — no Cloud Run, no Cloud SQL, no Firestore, no proxy. The iOS app calls upstream public APIs (MOA open-data) directly via `URLSession`.

**Why**: The product is built for a small family/friends cohort. Adding a server-side database would multiply GCP cost, introduce backup/permission burden, and create a compliance surface that an iPhone-local design avoids entirely. The MOA open-data endpoint is public and free, so a proxy adds latency and an operational burden without buying anything.

**When to revisit**: Only if (a) the user base outgrows TestFlight (≥ 80 distinct users) AND a feature genuinely cannot be done on-device (e.g. cross-device sync), OR (b) an upstream provider adds auth/rate-limits that require a server-side secret. Until then, on-device wins.

### II. No Backend in v1

Everything ships in the iOS app. ROC ↔ ISO date conversion, MOA JSON decoding, the unified `{success, data, error}` envelope shape (used for internal error typing only), and any future AMIS scraping all live in Swift.

**Why**: Fewest moving parts. One repo, one deploy target, one place to ship a fix. If an upstream changes shape, the iOS app ships an update; there is no separate service to also redeploy.

**Forbidden in v1**: any sibling `api/` directory, any FastAPI / Flask / Node service, any Cloud Run / Lambda / App Engine deploy artifact. If a future feature genuinely needs a server (e.g. credentials that cannot live on-device), it requires a constitution amendment first.

### III. Credentials Live Only in Keychain (NON-NEGOTIABLE)

Vendor passwords (deferred to a future feature once the AMIS vendor API is figured out) are subject to a strict storage rule:

- **Allowed**: iOS Keychain with biometry-gated access (LAContext required for the "記住密碼" opt-in).
- **Forbidden everywhere else**: `UserDefaults`, SwiftData, plist files, log lines (any level), crash reports, analytics events.
- Opting out of "記住密碼" MUST delete the Keychain entry **immediately**, not on next launch.

**Why**: Suppliers are trusting AgriPrice with credentials that grant access to their daily revenue data. A leak would be unrecoverable for trust, and there is no business reason that justifies persisting the password anywhere except the user's own biometry-gated Keychain.

### IV. Spec-Driven Development

Every new feature follows the Spec Kit flow: `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`. Code without a corresponding `specs/NNN-name/spec.md` is rejected at review. The legacy `agriprice_development_spec.md` is reference material, not a substitute for a per-feature spec.

**Why**: Specs catch ambiguity before it becomes code. With AI agents doing the implementation, the spec is the contract; a vague spec produces vague code.

### V. iOS 17 + SwiftUI + SwiftData + Swift Charts Only

The iOS app's tech stack is fixed:

- **UI**: SwiftUI (no UIKit views except where Apple frameworks force it).
- **Persistence**: SwiftData (no Core Data, no Realm, no SQLite directly).
- **Charts**: Swift Charts (no third-party charting libs).
- **Networking**: `URLSession` async/await (no Alamofire, no Combine-as-glue).
- **Secrets**: Keychain via a thin wrapper (no third-party Keychain libs).
- **Minimum iOS**: 17.0. No backport, no compatibility shims.

**Why**: A single supplier-of-one developer cannot maintain alternative stacks. Apple-native + iOS 17 minimum is the simplest possible substrate that supports SwiftData.

### VI. Friendly Error States Over Raw Errors

The user never sees an HTTP code, a stack trace, or an upstream error page. Every error path resolves to one of the zh-Hant strings defined in dev spec §18 (`網路連線異常,請稍後再試`, `查無此日期區間行情`, `供應商代號、小代號或密碼錯誤`, …). New error states require a new entry in §18, not a freeform string.

### VII. Simplicity Over Features

When in doubt: ship less. Defaults beat configuration. A hard-coded today–today date range beats a date picker the user has to learn. A bundled product list beats a fetched one. The MVP audience is small enough that "good enough for my family" is the bar — not "production-ready SaaS".

## Security Requirements

- **No vendor credential off-device**: see Principle III.
- **HTTPS-only for upstream calls**: no plaintext calls to MOA / AMIS even in dev. ATS exceptions are not allowed.
- **No tracking SDKs**: no Firebase Analytics, no Sentry that captures payloads, no Crashlytics with PII. Apple's built-in TestFlight crash logs only.
- **No upstream secrets in v1**: MOA open-data needs no API key. If a future upstream introduces one, that key cannot live in the app binary — at that point Principle II must be revisited (a proxy becomes unavoidable).

## Development Workflow

### Spec Kit gates

1. **/speckit-specify** — write `specs/NNN-name/spec.md` covering user stories (P1/P2/P3), edge cases, FRs, key entities, success criteria, assumptions. Reviewed before plan.
2. **/speckit-plan** — write `plan.md` with the implementation approach. Must declare which constitution principles apply and why none are violated. Reviewed before tasks.
3. **/speckit-tasks** — derive an ordered task list with explicit dependencies. Tests-first for FR-level behaviors.
4. **/speckit-implement** — execute tasks one at a time; each task ends with a green test.

### Test-first for protocol-shaped code

MOA response parsers, ROC ↔ ISO date converters, and any future AMIS HTML scrapers MUST have unit tests authored **before** the implementation. UI views are exempt (manual TestFlight check is acceptable for SwiftUI).

### Commits and branches

- Each feature lives on `NNN-short-name` branch (created by `.specify/scripts/...create-new-feature.ps1`).
- Commit messages follow `spec(NNN):`, `plan(NNN):`, `feat(NNN):`, `test(NNN):`, `fix(NNN):` prefixes.
- PRs to `main` require: green tests, spec + plan + tasks files committed, constitution check noted in PR body.

## Governance

This constitution supersedes the legacy `agriprice_development_spec.md` where they conflict, but does **not** replace it. The dev spec remains the canonical source for: SwiftData model field shapes (§7), API request/response shapes (§9–§13), error code strings (§17), and user-visible error message strings (§18).

Amendments require:

1. A short rationale (why the principle no longer fits).
2. A version bump (semver: MAJOR for removed principles, MINOR for new principles, PATCH for wording).
3. A migration note for any in-flight feature branches that the amendment affects.

Future Claude instances and contributors: when a request would violate a non-negotiable principle (I, III), refuse and surface the conflict rather than silently working around it.

**Version**: 2.0.0 | **Ratified**: 2026-05-13 | **Last Amended**: 2026-05-13

### Changelog

- **2.0.0** (2026-05-13) — Removed backend entirely. Principle II "Stateless Proxy" replaced with "No Backend in v1". iOS calls MOA directly via URLSession. Vendor credentials principle retained for the future vendor feature, deferred until the AMIS vendor API is figured out.
- **1.0.0** (2026-05-13) — Initial ratification.
