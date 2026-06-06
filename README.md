<p align="center">
  <img src="TrackProtein/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="120" style="border-radius: 27px;" alt="TrackProtein icon"/>
</p>

<h1 align="center">TrackProtein</h1>

<p align="center"><b>Track protein. Nothing else.</b><br/>
Log your protein in under 3 seconds — no calorie-counting bloat, no account, no ads.</p>

---

## Why

Most nutrition apps bury the one number many people actually care about — daily protein — under calorie tracking, ads, and $12–20/month subscriptions. TrackProtein does one thing fast:

- ⚡ **Speed** — one-tap favorites, lock-screen widget that deep-links straight into quick add
- 🔒 **Privacy** — data lives on-device (iCloud sync planned); no sign-up, no servers, no tracking
- 🎯 **One glance** — a single progress ring: today's grams vs. your goal

## Features (v1.0 — Phase 1)

- **Onboarding** — weight + goal (stay healthy / build muscle / lose fat) → science-based daily target (g/kg), fully adjustable
- **Quick add** — auto-focused numeric entry with +5/+10/+20/+30 chips, optional label, save-as-favorite
- **Favorites** — one-tap logging chips on the home screen, starter presets included
- **Progress ring** — animated, turns green when you hit your goal
- **Streaks** — consecutive goal-met days; an unfinished today never breaks it
- **History** — per-day summaries with goal checkmarks, edit/delete, log to past days
- **Widgets** — home screen (small ring, medium ring + stats) and lock screen (circular gauge, rectangular bar, inline); every widget taps through to quick add via `trackprotein://add`

## Roadmap

| Phase | Scope |
|---|---|
| ✅ **1 — Core loop** | Everything above |
| 🔜 **2 — Food data** | USDA / Open Food Facts search, barcode scanning (VisionKit), portion picker |
| 🔜 **3 — AI + Premium** | Photo → protein estimate (Claude API), natural-language logging, stats, StoreKit paywall |

Full product plan: [`PLAN.md`](PLAN.md) · Screen specs & design system: [`docs/design/`](docs/design/)

## Tech

- **SwiftUI + MVVM** (`@Observable` ViewModels), iOS 17+
- **SwiftData** in an App Group container — one store shared by app and widget extension
- **WidgetKit** — 5 widget families, timeline reloads on every data mutation
- **XcodeGen** — `project.yml` is the source of truth; the `.xcodeproj` is generated and gitignored
- **Zero third-party dependencies**

```
TrackProtein/
├── App/            # Entry, root routing, tabs
├── Core/
│   ├── Models/     # @Model: UserProfile, ProteinEntry, FavoriteFood
│   ├── Services/   # GoalCalculator, StreakCalculator, SharedStore, WidgetRefresher
│   └── Extensions/
├── Features/       # One folder per feature: View + ViewModel
└── Resources/
TrackProteinWidgets/ # Widget extension (shares Core/ sources)
```

## Build & run

Requirements: Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
git clone https://github.com/NemSothea/TrackProtein.git
cd TrackProtein
xcodegen generate
open TrackProtein.xcodeproj
```

Select the **TrackProtein** scheme and run. To install on a physical device, set your own `DEVELOPMENT_TEAM` in `project.yml` and re-run `xcodegen generate`.

The app icon is generated, not hand-drawn — tweak and regenerate with:

```bash
swift scripts/generate-app-icon.swift
```

## Disclaimer

TrackProtein provides general nutrition tracking and is **not medical advice**. Consult a professional for dietary guidance.
