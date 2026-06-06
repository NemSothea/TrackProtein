# TrackProtein — Task Memory

> Living task tracker. Update statuses here whenever work completes; this is the single source of truth for "where are we?". Strategy: **build all phases, deploy once at the end** (no App Store until Phase 3 done).

**Last updated:** 2026-06-06 · **Current focus:** Polish pass → Phase 2

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

## 🔧 Polish backlog (from /audit 2026-06-06)

- [ ] Replace guarded force unwraps `entry.label!` → nil-coalescing (HomeView, HistoryView)
- [ ] Cap QuickAdd DatePicker at `...Date.now` (block future-date logging)
- [ ] Read version from Bundle instead of hardcoded "1.0" (SettingsView)
- [ ] DayDetail: refresh after delete instead of force-dismiss
- [ ] Unit tests for `GoalCalculator` + `StreakCalculator` (needs test target in project.yml)
- [ ] Add medical disclaimer line to onboarding target step

## 🔜 Phase 2 — Food data

- [ ] F11 Food search — USDA FoodData Central + Open Food Facts clients (`Core/Services/FoodAPIClient`)
- [ ] F11 Search UI — results list, recent searches, local caching
- [ ] F13 Portion picker (per 100g / per serving / custom)
- [ ] F12 Barcode scan — VisionKit `DataScannerViewController` → OFF lookup
- [ ] F14 Smarter favorites (auto-suggest by time of day)

## 🔮 Phase 3 — AI + Premium

- [ ] Claude API proxy (Cloudflare Worker — keeps key off-device)
- [ ] F15 AI photo logging (vision → grams estimate w/ confidence range, editable before save)
- [ ] F16 Natural-language logging ("2 eggs and a shake")
- [ ] F17 Stats & insights (Swift Charts)
- [ ] StoreKit 2 paywall — $2.99/mo · $19.99/yr · lifetime + restore purchases
- [ ] F18 CSV export

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
