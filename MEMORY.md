# TrackProtein — Task Memory

> Living task tracker. Update statuses here whenever work completes; this is the single source of truth for "where are we?". Strategy: **build all phases, deploy once at the end** (no App Store until Phase 3 done).

**Last updated:** 2026-07-02 (macro model shipped to iPhone: protein 4.88 g / fat 3.55 g / carb 5.34 g MAE) · **Current focus:** re-run unit tests → M6 real-photo reality check → commit ML work → launch block

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
- [~] ~~USER ACTION: deploy proxy~~ — **superseded 2026-07-02**: replaced by own on-device Core ML model (see below). `proxy/` kept as reference until ML M5 removes the app's dependency.
- [ ] Test AI flow + paywall on device (use DEBUG dev-unlock for premium) — AI flow now waits on ML M5

## 🧠 ML — own on-device vision model (decided 2026-07-02, replaces Haiku proxy)

Plan: `ml/PLAN-ML.md` · runs log: `ml/RESULTS.md` · skill: `trackprotein-ml`. Nutrition5k → MobileNetV3-Large + macro head (protein q10/q50/q90 + fat/carb/kcal point estimates) → fp32 `.mlpackage` (fp16 failed parity; see RESULTS.md). Consequences accepted: no per-item breakdown v1, text logging (F16) dropped, AI stays premium-gated. Macros are display-only in the AI estimate (user decision 2026-07-02) — app still tracks protein only.

- [x] M1 Data — 3262/3265 overhead images (~1.2 GB), official depth splits, loader + sanity checks (2755 train / 507 test usable)
- [x] M1 Baseline-to-beat — predict-train-mean: **MAE 15.14 g**, coverage 75.1% on depth_test
- [x] M2 Baseline model — run `20260702-175528` (MobileNetV3-L, 224 px, 30 ep, 36 min): **MAE 4.86 g** on depth_test, raw coverage 47.5% (intervals too sharp)
- [x] M3 Iterate — multiplicative CQR (`calibrate.py`) met the ship gate; then **macro-head retrain** `20260702-190836` (user wants fat/carbs/kcal detail): **protein MAE 4.88 g, coverage 93.5%** (CQR ×0.986, α=.05) + fat 3.55 g / carb 5.34 g / kcal 50.8 MAE on depth_test
- [x] M4 Core ML export + parity — `ml/ProteinEstimator.mlpackage`: **fp32, 16.1 MB, parity 0.000 g** (fp16 failed parity twice: softplus overflow, then q90 accumulation — see RESULTS.md). Outputs: `quantiles` (3) + `macros` (fat/carb/kcal)
- [x] M5 App integration (code) — `LocalEstimationService.swift` (MLModel, lazy, eval-crop-parity preprocessing, confidence from interval width), mlpackage in `TrackProtein/Resources/`, AILogging photo-only (Describe mode removed), macro pills in estimate UI (display-only), `AIEstimationService.swift` kept as dead code with optional macro fields added to `AIEstimate`. Device build + install on iPhone 13 done 2026-07-02 (×2: protein-only, then macro model)
- [ ] M5 verify — unit-test run was interrupted (re-run `xcodebuild … test`); confirm on iPhone: photo → estimate → saved entry with Wi-Fi off
- [ ] M6 Reality check — 15–20 real meal photos vs USDA-computed truth (needs user's meals + iPhone)

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
