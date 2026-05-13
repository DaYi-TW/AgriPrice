# AgriPrice Constitution

## Core Principles

### I. On-Device First (NON-NEGOTIABLE)

All user-visible data is persisted on the iPhone via SwiftData. There is **no backend** in v1 — no Cloud Run, no Cloud SQL, no Firestore, no proxy. The iOS app calls upstream public APIs (MOA open-data) directly via `URLSession`.

**Why**: The product is built for a small family/friends cohort. Adding a server-side database would multiply GCP cost, introduce backup/permission burden, and create a compliance surface that an iPhone-local design avoids entirely. The MOA open-data endpoint is public and free, so a proxy adds latency and an operational burden without buying anything.

**When to revisit**: Only if (a) the user base outgrows TestFlight (≥ 80 distinct users) AND a feature genuinely cannot be done on-device (e.g. cross-device sync), OR (b) an upstream provider adds auth/rate-limits that require a server-side secret. Until then, on-device wins.

### II. No Backend Code in This Repo

This repository contains the iOS app only. Backend code — if any — lives in **a separate repository** and is treated as an external dependency, exactly like MOA's open-data service.

**What this repo never contains**: a sibling `api/` directory, FastAPI / Flask / Node sources, Cloud Run / Lambda / App Engine deploy manifests, GCP / AWS infrastructure-as-code.

**What iOS may call**:

- MOA open-data API (public, no auth) — used by feature 001.
- The `chill-api` Cloud Run service (separately maintained at `https://chill-api-240848983153.asia-east1.run.app/`) — used by feature 002 for vendor scraping of AMIS. iOS treats this as a black-box upstream: it owns the request/response shape contract and we adapt to its `error_code` values.

**Why**: Fewest moving parts in this repo. The vendor data source (AMIS) needs login + HTML scraping that genuinely cannot be done on-device, so a service is unavoidable — but that service is somebody else's problem; it ships on its own cadence, and we only consume its public API.

**When iOS needs a new external service**: capture the URL, request/response shape, and error codes in that feature's `plan.md`. Do not commit the service's code here.

### III. Credentials Live Only in Keychain (NON-NEGOTIABLE)

Vendor passwords (供應代號 + 小代號 + 密碼; the password specifically) are subject to a strict storage rule:

- **Allowed**: iOS Keychain only, with biometry-gated access (`SecAccessControl` with `.biometryCurrentSet` + `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`). The user must opt in with the "記住密碼" toggle; reading the password back requires Face ID / Touch ID via `LAContext`.
- **Forbidden everywhere else**: `UserDefaults`, SwiftData, plist files, log lines (any level), crash reports, analytics events. Never `print(password)`, never `NSLog`, never `os_log`.
- The non-secret identifiers (供應代號 / 小代號) MAY be persisted in SwiftData (`VendorQueryProfile`) so the login form can pre-fill — but the password is always Keychain-only.
- Opting out of "記住密碼" MUST delete the Keychain entry **immediately**, not on next launch.
- The chill-api response is also off-limits for the password: the request body carries it, the response never echoes it. iOS must not log the request body.

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

**Version**: 2.1.0 | **Ratified**: 2026-05-13 | **Last Amended**: 2026-05-13

### Changelog

- **2.1.0** (2026-05-13) — Principle II reworded: "No Backend in v1" → "No Backend Code in This Repo". The vendor feature (002) needs AMIS scraping which can't be done on-device, so a separately-maintained `chill-api` Cloud Run service is consumed as an external dependency. Principle III tightened with concrete Keychain access flags and a clarification that 供應代號/小代號 may live in SwiftData, but password is Keychain-only with biometry.
- **2.0.0** (2026-05-13) — Removed backend entirely from this repo. Principle II "Stateless Proxy" replaced with "No Backend in v1". iOS calls MOA directly via URLSession.
- **1.0.0** (2026-05-13) — Initial ratification.
