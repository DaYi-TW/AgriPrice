# AgriPrice Constitution

## Core Principles

### I. On-Device First (NON-NEGOTIABLE)

All user-visible data is persisted on the iPhone via SwiftData. The backend stores **nothing** about users — no profiles, no query history, no favorites, no credentials. Cloud SQL and Firestore are explicitly forbidden in v1. The single allowed server-side state is **transient request memory** while a proxy call is in flight.

**Why**: The product is built for a small family/friends cohort. Adding a server-side database would multiply GCP cost, introduce backup/permission burden, and create a compliance surface that an iPhone-local design avoids entirely.

**When to revisit**: Only if the user base outgrows TestFlight (≥ 80 distinct users) AND a feature genuinely cannot be done on-device (e.g. cross-device sync). Until both are true, on-device wins.

### II. Stateless Proxy

The FastAPI service on Cloud Run is a **stateless adapter** that fetches from MOA / AMIS, parses, normalizes to the unified `{success, data, error}` envelope (dev spec §9), and returns. No DB. No cache layer beyond per-request in-memory. No background jobs. No queues.

**Why**: Statelessness is the cheapest way to keep Cloud Run safe to redeploy, easy to reason about, and impossible to leak vendor credentials from.

### III. Credentials Live Only in Keychain (NON-NEGOTIABLE)

Vendor passwords are subject to a strict storage rule:

- **Allowed**: iOS Keychain with biometry-gated access (LAContext required for the "記住密碼" opt-in).
- **Forbidden everywhere else**: `UserDefaults`, SwiftData, plist files, log lines (any level), backend DB, backend cache, backend temp files, request log middleware, error reports, crash reports, analytics events.
- The proxy MUST redact `password` → `***` in every log line, including request-replay debug logs.
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

The user never sees an HTTP code, a stack trace, or an upstream error page. Every error path resolves to one of the strings defined in dev spec §18 (`網路連線異常,請稍後再試`, `查無此日期區間行情`, `供應商代號、小代號或密碼錯誤`, …). New error states require a new entry in §18, not a freeform string.

### VII. Simplicity Over Features

When in doubt: ship less. Defaults beat configuration. A hard-coded today–today date range beats a date picker the user has to learn. A bundled product list beats a fetched one. The MVP audience is small enough that "good enough for my family" is the bar — not "production-ready SaaS".

## Security Requirements

- **No vendor credential server-side**: see Principle III.
- **HTTPS-only for proxy ↔ MOA / AMIS**: no plaintext upstream calls even in dev.
- **No tracking SDKs**: no Firebase Analytics, no Sentry that captures payloads, no Crashlytics with PII. Apple's built-in TestFlight crash logs only.
- **API rate-limiting at the proxy**: a single Cloud Run instance with default concurrency is enough at v1 scale; if abuse becomes a concern, add an IP-based limiter at the proxy, not at MOA.
- **Secrets management**: any Cloud Run env vars (e.g. AMIS scrape selectors that might change) live in GCP Secret Manager, not in the repo or in `cloudbuild.yaml` literals.

## Development Workflow

### Spec Kit gates

1. **/speckit-specify** — write `specs/NNN-name/spec.md` covering user stories (P1/P2/P3), edge cases, FRs, key entities, success criteria, assumptions. Reviewed before plan.
2. **/speckit-plan** — write `plan.md` with the implementation approach. Must declare which constitution principles apply and why none are violated. Reviewed before tasks.
3. **/speckit-tasks** — derive an ordered task list with explicit dependencies. Tests-first for FR-level behaviors.
4. **/speckit-implement** — execute tasks one at a time; each task ends with a green test.

### Test-first for protocol-shaped code

API endpoint contracts, MOA response parsers, and AMIS vendor scrapers MUST have unit tests authored **before** the implementation. UI views are exempt (manual TestFlight check is acceptable for SwiftUI).

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

**Version**: 1.0.0 | **Ratified**: 2026-05-13 | **Last Amended**: 2026-05-13
