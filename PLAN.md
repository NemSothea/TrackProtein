# TrackProtein — Product & Build Plan

> **One-liner:** The fastest way to hit your daily protein goal. Log protein in under 3 seconds — no calorie-counting bloat.
>
> Platform: **iOS native (SwiftUI + MVVM)** · Data: **SwiftData + CloudKit (iCloud sync)** · Model: **Freemium subscription**

---

## 1. Market Analysis & Positioning

### The gap (why this app should exist)
Articles like Lifehacker's "best apps to track protein" exist because people search for *protein-only* tracking — and keep landing on full macro/calorie apps. The current landscape:

| App | Strength | Weakness for protein-focused users |
|---|---|---|
| **MyFitnessPal** | Huge food DB (18M+ foods) | Bloated, ad-heavy, protein buried under calorie tracking, $19.99/mo premium |
| **MacroFactor** | Adaptive targets, verified DB | No free tier ($11.99/mo), built for serious macro dieters |
| **Cronometer** | Micronutrient/amino acid accuracy | Overkill UI for "did I hit 140g today?" |
| **Protein Pal** | Simple, protein-only | Limited logging methods, basic stats |

### TrackProtein's positioning
**"Protein tracking, nothing else."**
- ⚡ **Speed**: log from the lock screen widget in one tap
- 🔒 **Privacy**: data lives on-device + your iCloud — no account, no server, no email signup
- 🤖 **Smart**: AI photo logging when you don't know the grams (premium)
- 🎯 **One number**: today's protein vs. goal — the whole home screen

### Target users
1. Gym-goers told to "eat 1.6–2.2 g/kg protein" who don't care about calories
2. People on GLP-1 medications (doctors emphasize protein intake — fast-growing segment)
3. Older adults advised to maintain muscle mass
4. Vegetarians/vegans monitoring protein adequacy

---

## 2. Feature Requirements

### Phase 1 — MVP (ship this first)
**Goal: a v1.0 on the App Store that nails the core loop.**

| # | Feature | Notes |
|---|---|---|
| F1 | Onboarding: weight, goal (maintain/build muscle/lose fat) → computed daily protein target (g/kg formula), manually overridable | 3 screens max |
| F2 | Home screen: big circular progress ring (today's grams / goal), today's log list | The entire app in one glance |
| F3 | Quick manual entry: numeric pad → grams, optional label | < 3 seconds to log |
| F4 | Favorites / presets: save "Chicken breast 31g", "Protein shake 25g", re-log in one tap | Key speed feature |
| F5 | Edit / delete entries, log to past days | |
| F6 | History: calendar heat-map + daily streak counter | Streaks drive retention |
| F7 | SwiftData persistence + CloudKit sync | Free with Apple stack |
| F8 | Home-screen & lock-screen widgets (WidgetKit): progress ring + quick-add | Top differentiator for speed |
| F9 | Daily reminder notifications ("You're 40g short — log dinner?") | Smart, goal-aware |
| F10 | Apple Health (HealthKit) write/read dietary protein | Interop users expect |

### Phase 2 — Food database & barcode (v1.1–1.2)
| # | Feature | Notes |
|---|---|---|
| F11 | Food search: **USDA FoodData Central** (free API) + **Open Food Facts** (free, open) | Cache common results locally |
| F12 | Barcode scanning via `VisionKit DataScannerViewController` → Open Food Facts lookup | No paid SDK needed |
| F13 | Portion-size picker (per 100g / per serving / custom) | |
| F14 | Recent foods & smarter favorites (auto-suggest by time of day) | |

### Phase 3 — AI photo logging + Premium (v1.3+)
| # | Feature | Notes |
|---|---|---|
| F15 | Snap a meal photo → Claude API (vision) estimates protein grams with food breakdown + confidence | The "wow" feature; gate behind premium |
| F16 | Natural-language logging: "2 eggs and a greek yogurt" → parsed grams | Same API, cheap text-only calls |
| F17 | Stats & insights: weekly averages, best/worst days, per-food protein sources chart | Premium |
| F18 | Data export (CSV) | Premium |
| F19 | Apple Watch app: glanceable ring + quick-add | Premium or free — decide by demand |

### Freemium split
| Free (forever) | Premium (~US$2.99/mo or $19.99/yr or $39.99 lifetime) |
|---|---|
| Manual entry, favorites, goal, widgets | AI photo + natural-language logging |
| Food search & barcode (limited: e.g. 5/day) | Unlimited search & barcode |
| 30-day history | Full history + stats + insights + export |
| iCloud sync | Apple Watch app |

> Pricing logic: undercut MacroFactor ($11.99/mo) and MFP ($19.99/mo) hard — you're selling *less* (in a good way), so charge less. Lifetime option converts the subscription-averse.

---

## 3. Technical Architecture

```
TrackProtein/
├── App/                      # App entry, DI container
├── Features/                 # MVVM, one folder per feature
│   ├── Onboarding/           #   View + ViewModel
│   ├── Home/                 #   Progress ring, today log
│   ├── LogEntry/             #   Manual entry, favorites
│   ├── FoodSearch/           #   USDA/OFF search (Phase 2)
│   ├── BarcodeScan/          #   VisionKit scanner (Phase 2)
│   ├── AILogging/            #   Photo/NL logging (Phase 3)
│   ├── History/              #   Calendar, streaks
│   └── Stats/                #   Charts (Swift Charts)
├── Core/
│   ├── Models/               # SwiftData @Model: ProteinEntry, FavoriteFood, UserProfile
│   ├── Services/             # HealthKitService, NotificationService,
│   │                         # FoodAPIClient, AIEstimationService, StoreKitService
│   └── Extensions/
├── Widgets/                  # WidgetKit extension (App Group shared container)
└── WatchApp/                 # Phase 3
```

**Stack decisions**
- **SwiftUI + MVVM** (`@Observable` ViewModels) — matches your existing workflow
- **SwiftData with CloudKit** (`ModelConfiguration(cloudKitDatabase:)`) — sync for free, no backend
- **App Group** shared container so widgets read the same store
- **StoreKit 2** for subscriptions (+ optionally RevenueCat later for analytics/paywall testing)
- **Swift Charts** for stats
- **VisionKit** for barcode (no third-party SDK)
- **Claude API** (`claude-haiku-4-5` for cost-efficiency on photo estimates) via a **thin proxy** — never ship the API key in the app. Smallest option: a single Cloudflare Worker / Supabase Edge Function that forwards requests and checks an App Store receipt. (~1 day of work, ~$0/mo at low volume.)
- Min target: **iOS 17** (SwiftData requirement)

**Data model (core)**
```swift
@Model class ProteinEntry { var grams: Double; var label: String?; var date: Date; var source: LogSource } // manual|favorite|search|barcode|ai
@Model class FavoriteFood { var name: String; var grams: Double; var sortOrder: Int; var lastUsed: Date }
@Model class UserProfile  { var weightKg: Double; var goalType: GoalType; var dailyTargetGrams: Double; var reminderTime: Date? }
```

---

## 4. Timeline — Fast-Track (4 weeks to monetized launch)

Assumes **full-time, with Claude Code generating most of the implementation**. The bottlenecks are design decisions, device testing, and App Review — not typing code.

### Week 1 — Core loop, working on your phone
| Day | Deliverable |
|---|---|
| 1 | Figma mockups (Home ring, quick-add, onboarding) — lock visuals in one sitting |
| 1–2 | Xcode project scaffolded: SwiftUI + SwiftData/CloudKit + App Group + Widget target |
| 2–4 | Onboarding → goal calc → manual entry → favorites → progress ring → history list |
| 5 | Streaks + edit/delete + past-day logging; running on your device daily |

### Week 2 — Differentiators + beta
| Day | Deliverable |
|---|---|
| 6–7 | Lock-screen & home-screen widgets with one-tap quick-add |
| 8 | Barcode scan (VisionKit → Open Food Facts) — it's ~1 day, not 2 weeks |
| 9 | Food search (USDA + OFF) with portion picker |
| 10 | App icon, polish pass, **TestFlight build out to 10–20 testers** |

### Week 3 — Premium + AI while beta feedback arrives
| Day | Deliverable |
|---|---|
| 11 | Cloudflare Worker proxy for Claude API (keeps key off-device) |
| 12–13 | AI photo logging + natural-language entry ("2 eggs and a shake") |
| 14 | StoreKit 2 paywall: $2.99/mo · $19.99/yr · lifetime; restore purchases |
| 15 | Stats screen (Swift Charts), fix top beta complaints |

### Week 4 — Launch
| Day | Deliverable |
|---|---|
| 16–17 | App Store screenshots, copy, privacy labels, privacy policy page, medical disclaimer |
| 18 | Submit. Review is typically 24–48 h now |
| 19–20 | Buffer for rejection fixes / final beta issues |
| 🚀 | **v1.0 live with monetization, end of week 4** |

### Deliberately cut from v1.0 (ship in v1.1, ~1 week post-launch)
- HealthKit sync, smart reminders, calendar heat-map, CSV export, Apple Watch app
- None of these drive day-1 retention; streaks + widgets do

> **Reality check:** 4 weeks holds if you make design decisions fast and test on-device daily. A safer commitment is **5–6 weeks**; 3 months was the no-AI-assistance number.

### Part-time alternative (~15 h/wk)
Same order, ~2.5× duration: **v1.0 in ~6–8 weeks.**

---

## 5. Requirements & Costs

### What you need
| Item | Cost |
|---|---|
| Apple Developer Program | **$99/yr** |
| Mac + Xcode 16+ | already have |
| USDA FoodData Central API key | free |
| Open Food Facts API | free |
| Claude API (Haiku vision: a photo estimate ≈ $0.001–0.003) | ~$5–20/mo at early scale — premium revenue covers it |
| Proxy (Cloudflare Workers free tier / Supabase free tier) | $0 |
| App icon / branding (DIY with SF Symbols + Figma, or commission) | $0–300 |
| **Total to launch** | **≈ $99–400 + your time** |

### App Store / legal checklist
- [ ] Privacy policy (required — easy since data is on-device; generate one page)
- [ ] App Privacy "nutrition labels" in App Store Connect
- [ ] HealthKit usage description strings + entitlement
- [ ] Camera usage description (barcode/photo)
- [ ] Medical disclaimer: "not medical advice" (nutrition apps get reviewed for this)
- [ ] Subscription terms + restore purchases button (App Review requirement)
- [ ] Localization: English first; **Khmer** later is a niche edge competitors won't touch

---

## 6. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Crowded market / "MyFitnessPal already exists" | Positioning IS the moat: speed + privacy + protein-only. Don't drift into calorie tracking. |
| AI protein estimates are inaccurate | Show confidence ranges ("~25–35g"), always let users adjust before saving, label as estimate |
| Scope creep kills momentum | Phases are hard gates. Phase 1 ships before Phase 2 starts. |
| Open Food Facts coverage gaps (esp. Asian products) | Fall back to USDA search; let users save custom foods (becomes a favorite) |
| Subscription conversion is low | Lifetime purchase option; free tier generous enough to retain, limited enough to convert |
| App Review rejection (health claims) | No medical claims anywhere; disclaimer in onboarding & App Store description |

---

## 7. Success Metrics (post-launch)

- **Activation**: % of installs that log ≥1 entry on day 1 (target: >60%)
- **Retention**: D7 ≥ 25%, D30 ≥ 12% (habit apps live or die here — streaks & widgets drive this)
- **Speed**: median time-to-log < 5 s (instrument it)
- **Conversion**: free → premium ≥ 3–5%
- App Store rating ≥ 4.6 (prompt for review after a 7-day streak — happiest moment)

---

## 8. Immediate Next Steps

1. **Design first** (3–4 days): Figma mockups of Home (progress ring), Quick-add, Onboarding, Widget — lock the visual identity before code
2. **Scaffold the Xcode project**: SwiftUI + SwiftData + CloudKit + App Group + Widget extension
3. **Build the core loop**: onboarding → goal → log → ring fills → streak
4. **TestFlight to 10–20 friends/gym buddies** at end of Phase 1, week 4
5. Submit v1.0 → start Phase 2 while waiting for review
