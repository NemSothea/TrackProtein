# TrackProtein — Task Memory

> Living task tracker. Update statuses here whenever work completes; this is the single source of truth for "where are we?". Strategy: **build all phases, deploy once at the end** (no App Store until Phase 3 done).

**Last updated:** 2026-06-06 (Phase 3 built) · **Current focus:** Deploy AI proxy (user action) → on-device testing → launch block

---

## ✅ Phase 1 — Core loop (DONE except CloudKit)

- [x] Project scaffold (XcodeGen, SwiftUI + MVVM + SwiftData, iOS 17)
- [x] F1 Onboarding — weight + goal → g/kg target, adjustable
- [x] F2 Home — progress ring, today's log
- [x] F3 Quick manual entry (decimal pad, +5/10/20/30 chips)
- [x] F4 Favorites — one-tap chips, save-as-favorite, starter presets
- [x] F5 Edit/delete entries, log to past days
- [x] F6 History + streaks (heat-map deferred to post-launch)
- [x] F8 Widgets — small/medium + lock-screen circular/rectangular/inline, App Group store, `trackprotein://add` deep link
- [x] App icon (generated — `scripts/generate-app-icon.swift`)
- [x] Installed & running on iPhone 13 ("Sothea007")
- [x] GitHub repo + README + design docs + .claude tooling
- [ ] F7 CloudKit sync — ⏸ blocked: needs paid Apple Developer account ($99)

## 🔧 Polish backlog (from /audit 2026-06-06) — ✅ DONE

- [x] Replace guarded force unwraps → `ProteinEntry.displayName` (HomeView, HistoryView)
- [x] Cap QuickAdd DatePicker at `...Date.now`; clamp presetDate to now
- [x] Read version from Bundle instead of hardcoded "1.0" (SettingsView)
- [x] DayDetail: live `@Query` — deletes update in place, no force-dismiss, empty state added
- [x] Unit tests — `TrackProteinTests` target (Swift Testing), 12 tests green for GoalCalculator + StreakCalculator
- [x] Medical disclaimer line in onboarding target step
- [x] CloudKit-compatible models — all @Model properties now have defaults (flip `cloudKitDatabase` at launch)

## ✅ Phase 2 — Food data (built 2026-06-06; needs real-device testing)

- [x] F11 Food search — `FoodSearchService`: OFF (primary, no key) + USDA (DEMO_KEY, rate-limited — replaceable constant) merged & deduped. ⚠️ OFF `sort_by=unique_scans_n` causes 503 — don't re-add
- [x] F11 Search UI — debounced (400ms), in-memory cache, recent searches (UserDefaults), empty/offline states
- [x] F13 Portion picker — per-100g slider + quick chips (50/100/150/200g), per-serving stepper fallback, save-as-favorite
- [x] F12 Barcode scan — VisionKit DataScanner (EAN13/8, UPC-E, Code128) → OFF v2 lookup → portion picker; camera-unavailable + product-not-found states; camera permission string added
- [x] F14 Smarter favorites — `lastUsedHour` on FavoriteFood, chips ordered by circular hour-distance then recency
- [ ] Verify on iPhone: search results quality, barcode scan flow (scanner needs real camera — simulator can't test)
- [ ] Consider: real USDA API key before launch (DEMO_KEY = ~30 req/hr shared limit)

## ✅ Phase 3 — AI + Premium (built 2026-06-06)

- [x] Claude API proxy — `proxy/worker.js` (Cloudflare Worker, fixed prompt + JSON schema server-side, APP_SECRET auth, model `claude-haiku-4-5` per PLAN §3). Deploy guide: `proxy/README.md`
- [x] F15 AI photo logging — PhotosPicker + camera → downscale 1024px JPEG → proxy → editable estimate with range + confidence → `ProteinEntry(source: .ai)`
- [x] F16 Natural-language logging ("2 eggs and a shake") — same sheet, Describe mode
- [x] F17 Stats — Swift Charts: 7/30-day bars vs goal line, average, goal-hit count, best day, top 5 sources. Premium-gated
- [x] StoreKit 2 paywall — monthly $2.99 / yearly $19.99 / lifetime $39.99, restore, `TrackProtein.storekit` local config wired into scheme; DEBUG dev-unlock toggle (StoreKit config doesn't apply to devicectl launches)
- [x] F18 CSV export — ShareLink in Settings, premium-gated
- [ ] **USER ACTION: deploy proxy** (Cloudflare account + Anthropic API key, ~10 min — `proxy/README.md`), then set `proxyURL`/`appSecret` in `AIEstimationService.swift` (⚠️ don't commit the secret — move to a gitignored config if needed)
- [ ] Test AI flow + paywall on device (use DEBUG dev-unlock for premium)

## 🚀 Launch block (after Phase 3 — single deploy)

- [ ] Apple Developer enrollment ($99) → enables CloudKit (F7) + TestFlight
- [ ] Enable CloudKit in `SharedStore` + entitlements
- [ ] App Store screenshots (reuse for README), copy, keywords
- [ ] Privacy policy page + App Privacy labels
- [ ] TestFlight round → fix top issues → submit

## 📌 Decisions log

| Date | Decision |
|---|---|
| 2026-06-06 | iOS native (SwiftUI), all 4 logging methods, freemium, on-device + iCloud |
| 2026-06-06 | Fast-track plan; HealthKit/reminders/heat-map/Watch deferred to post-launch |
| 2026-06-06 | Signing: personal team `PBJ22NG3WU` (not KOSIGN/Bizplay work teams) |
| 2026-06-06 | **No deployment until all phases complete** — build full product, launch once |
