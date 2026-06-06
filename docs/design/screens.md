# TrackProtein — Screen Designs

Status: ✅ built (Phase 1) · 🔜 planned. Tokens/components: see [design-system.md](design-system.md).

## Navigation map

```
RootView
├── no profile → Onboarding (3 steps, full-screen)
└── profile    → MainTabView
    ├── Today    (Home) ──┬── sheet: QuickAdd (add)
    │                     └── sheet: QuickAdd (edit entry)
    ├── History ───────────── sheet: DayDetail ── sheet: QuickAdd (past day)
    └── Settings
```

---

## 1. Onboarding ✅ — `Features/Onboarding/`

3 steps, no skipping, ~30 seconds total. Completes by inserting `UserProfile` + 3 starter favorites (Protein Shake 25g, Chicken Breast 31g, 3 Eggs 18g) — RootView auto-switches to tabs.

### Step 1 — Welcome
```
┌─────────────────────────┐
│                         │
│        ◔ (icon 80pt)    │   chart.pie.fill, orange
│      TrackProtein       │   .largeTitle.bold
│  Track protein.         │
│  Nothing else.          │   .title3 .secondary, centered
│  Log in under 3 seconds…│
│                         │
│  ┌───────────────────┐  │
│  │    Get Started    │  │   primary button
│  └───────────────────┘  │
└─────────────────────────┘
```

### Step 2 — About you
```
│  About you              │   .largeTitle.bold, leading
│                         │
│        70 kg            │   44pt rounded bold, orange
│  ──────●──────────      │   Slider 30–200, step 1
│   Your body weight      │
│                         │
│  ┌ ♥ Stay Healthy     ┐ │   selection cards,
│  ┌ 🏋 Build Muscle  ✓ ┐ │   selected = orange stroke
│  ┌ 🔥 Lose Fat        ┐ │   + checkmark
│                         │
│  [     Continue      ]  │
```
- Selecting a goal clears any custom target (recompute from formula).

### Step 3 — Your daily target
```
│  Your daily target      │
│                         │
│         126g            │   72pt rounded bold, orange
│     protein per day     │
│      ⊖        ⊕        │   ±5g, clamps 30–400
│                         │
│  Based on 70 kg × 1.8   │   .footnote .secondary
│  g/kg for build muscle. │
│  You can change this…   │
│                         │
│  [   Start Tracking  ]  │
```

---

## 2. Home / Today ✅ — `Features/Home/`

The whole app in one glance. List(.insetGrouped), nav title "Today", toolbar `plus.circle.fill` → QuickAdd sheet.

```
┌─────────────────────────┐
│ Today              (+)  │
│                         │
│        ╭──────╮         │   Progress ring 230pt
│       │   85   │        │   52pt rounded bold
│       │ of 140g │       │   .headline .secondary
│       │ 55g to go│      │   orange (green if met)
│        ╰──────╯         │
│     (🔥 4 day streak)   │   capsule badge, hidden if 0
│                         │
│ FAVORITES               │
│ (Shake)(Chicken)(Eggs)→ │   horizontal chips, 1 tap = logged
│                         │
│ LOGGED TODAY            │
│ Chicken Breast     31g  │   tap → edit sheet
│ 12:30                   │   swipe ← → delete
│ Protein Shake      25g  │
│ 08:15                   │
└─────────────────────────┘
│ [Today] [History] [Set] │   TabView, orange tint
```
States:
- **Empty today**: "Nothing logged yet — tap a favorite or hit +"
- **Goal met**: ring green/mint, "Goal hit!" label with checkmark
- **Over goal**: ring stays full, count keeps rising (never punish)
- Favorite chip: tap logs instantly (`withAnimation`); long-press → Delete Favorite

---

## 3. Quick Add / Edit ✅ — `Features/LogEntry/`

One sheet, two modes (`entry:` = edit, `presetDate:` = past-day). Detents `[.medium, .large]`, grams field auto-focused with decimal pad — fastest possible manual log.

```
┌─────────────────────────┐
│ Cancel   Log Protein  Log│  Log/Save bold, disabled until grams > 0
│                         │
│ PROTEIN                 │
│  32              g      │   40pt rounded bold input
│ (+5)(+10)(+20)(+30)     │   bordered orange, additive
│                         │
│ DETAILS (OPTIONAL)      │
│ e.g. Chicken Breast     │
│ When        Jun 6, 12:30│   DatePicker (enables past-day logging)
│ Save as favorite    ⊙   │   add-mode only; disabled until label
│ Favorites appear on the │
│ home screen for one-tap…│
└─────────────────────────┘
```
- Comma accepted as decimal separator (`32,5` → 32.5).
- Save-as-favorite also creates the `FavoriteFood` alongside the entry.

---

## 4. History ✅ — `Features/History/`

```
┌─────────────────────────┐
│ History                 │
│                         │
│ 🔥  4 days              │   .title2.bold
│     Current streak      │   flame gray when streak = 0
│                         │
│ DAYS                    │
│ Friday            142g ✓│   green when ≥ goal,
│ Jun 6, 2026             │   orange + ○ when under
│ Thursday          151g ✓│
│ Jun 5, 2026             │
│ Wednesday          98g ○│
└─────────────────────────┘
```
- Tap day → **DayDetail sheet**: total vs goal, entry list (swipe-delete), `+` logs to that past day (QuickAdd preset to 12:00 of that date), Done dismisses.
- Empty: "No entries yet — start logging on the Today tab."
- Known limit (accepted for MVP): days judged against *current* goal, not historical.

---

## 5. Settings ✅ — `Features/Settings/`

```
┌─────────────────────────┐
│ Settings                │
│ YOUR STATS              │
│ Weight            70 kg │
│ ──────●──────────       │
│ Goal       Build Muscle⌄│
│                         │
│ DAILY TARGET            │
│ Daily target   126g  −+ │   stepper ±5, 30–400
│ Use recommended (126g)  │   shown only when overridden
│ Recommended: 126g — 1.8 │
│ g/kg… Not medical advice│
│                         │
│ ABOUT                   │
│ Version            1.0  │
└─────────────────────────┘
```
- Edits write directly to `UserProfile` via `@Bindable` — live everywhere instantly.

---

## 6. Planned screens 🔜

| Screen | Phase | Design intent |
|---|---|---|
| **Widgets** ✅ built | 1 | Small: mini ring (10pt stroke, 26pt rounded number). Medium: ring + "Xg to go"/"Goal hit!" + streak. Lock screen: circular gauge, rectangular progress bar, inline text. All tap → `trackprotein://add` (QuickAdd opens). Unconfigured state: "Open TrackProtein to set your goal" |
| **Food Search** | 2 | Search bar → results "name · brand · Xg per serving"; portion stepper; reuses entry-row pattern |
| **Barcode Scan** | 2 | Full-screen camera, center reticle, result card slides up bottom: name + grams + [Log] |
| **AI Photo Log** | 3 | Camera/photo → breakdown card "Chicken ~30g · Rice ~4g · Total ~34g (range 28–40g)" — always editable before save, confidence shown |
| **Paywall** | 3 | Hero ring graphic, 3 bullets (AI logging · full history · stats), price cards Monthly/Yearly/Lifetime, restore link |
| **Stats** | 3 | Weekly bar chart (Swift Charts) vs goal line, averages, top protein sources |

Future screens must reuse: entry-row pattern, ring visual language, sheet detents, orange/green role split.
