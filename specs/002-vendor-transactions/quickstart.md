# Quickstart: Vendor Transactions

How to validate feature 002 on a real iPhone after the Xcode project is wired (see `specs/003-ios-shell/quickstart.md` for one-time Xcode setup).

## Prerequisites

- A physical iPhone running iOS 17+ with Face ID or Touch ID enrolled.
- A real **AMIS 供應商 account** (供應代號 / 小代號 / 密碼). The simulator works for P1 only — biometry tests need a device.
- The chill-api service reachable at `https://chill-api-240848983153.asia-east1.run.app/`. A `GET /` smoke check should return a JSON body before starting.

## P1 — Today's transactions (no remember)

1. Build & run on the device.
2. Tap **成交** in the tab bar. The login form appears with three labeled fields and a 查詢 button. The 密碼 field is masked.
3. Enter valid 供應代號 + 小代號 + 密碼. Leave 記住密碼 off. Tap 查詢.
4. Within ~10 s, the screen swaps to the results: **今日總利潤** card, **本年累計** card, then one row per market with market name, product name, average price, quantity.
5. **Empty-state**: re-run on a date the supplier has no sales (or use a known-quiet supplier). Both totals show, and an inline `今天無銷售資料` appears under them — **not** an error.
6. **Wrong password**: change one character of the password, tap 查詢. The form stays visible; inline `登入失敗,請確認供應商號碼/密碼` appears; 密碼 field is cleared; 供應代號 + 小代號 are preserved.
7. **Offline**: turn airplane mode on, tap 查詢. Inline `網路連線異常,請稍後再試`; credentials preserved.
8. **Multi-tap**: tap 查詢 twice in quick succession. Only one network request fires (verifiable in Charles / a debug log line showing `cancelled=true` on the first attempt).

## P2 — 記住密碼 with biometry

9. With airplane mode off and valid creds entered, toggle **記住密碼** on. Tap 查詢. Expect a Face ID / Touch ID prompt **before** the request fires (system framework decides timing; on first save it may be implicit).
10. After success, kill the app from the multitasker.
11. Reopen → tap **成交**. The form pre-fills 供應代號 + 小代號 from SwiftData; 密碼 is blank but the keyboard is not focused on it.
12. Tap 查詢. A Face ID / Touch ID prompt appears with reason `解鎖以讀取供應商密碼`. Authenticate → the request fires → results render.
13. **Toggle off**: in the results view (or after returning to the form), toggle 記住密碼 off. Within 1 s, the Keychain entry must be gone — verify with the Keychain inspector in a development build, or by re-launching the app and confirming the next 查詢 requires manual password entry.
14. **No biometry enrolled**: on a test device with biometry disabled in Settings → Face ID, flip 記住密碼 on. It bounces back to off with inline `此裝置未設定 Face ID / Touch ID`.
15. **Deny the biometric prompt**: at step 12, tap Cancel on the Face ID sheet. The 密碼 field becomes editable so the user can type the password manually.

## P3 — Home footer card

16. After at least one successful 成交 query, switch to the **首頁** tab.
17. At the bottom of Home, a small card reads `上次查詢成交: <供應代號>-<小代號> (HH:mm)`.
18. Tap the card → the **成交** tab opens with 供應代號 + 小代號 pre-filled.
19. On a fresh install (delete app, reinstall), the Home footer card is **absent** until the first successful 成交 query.

## Debug-log sanity check (constitution §III audit)

Before any TestFlight submission:

1. Run the app under Xcode with the Console open.
2. Filter the device log for the literal password string used in the test account (must be a string you would notice).
3. Repeat the P1 + P2 flows above.
4. The filter must show **zero hits**. If anything matches, fail the audit — that's SC-003 failing.
5. Also grep for `supply_no`, `supply_sub`, and `credentials` — the request body fields. The only allowed hits are in source-file paths, not runtime log lines.

## Known non-issues

- An "未受信任的開發者" prompt on first install is iOS dev-mode behavior, not a feature bug.
- A 1–2 s delay before the Face ID sheet appears on cold start is normal; iOS warms the secure enclave context.
