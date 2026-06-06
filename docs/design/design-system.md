# TrackProtein — Design System

Design principle: **one glance, one tap**. Every screen answers "how am I doing?" instantly; every log action completes in ≤ 3 seconds. When in doubt, remove.

## Colors

| Token | Value | Usage |
|---|---|---|
| `Color.proteinOrange` | `#FF6B36` (1.0, 0.42, 0.21) | Brand accent: ring, buttons, grams, streak, tints |
| `Color.proteinDeep` | `#D9401A` (0.85, 0.25, 0.10) | Ring gradient end |
| `.green` / `.mint` (system) | — | Goal-met state only (ring turns green, checkmarks) |
| System semantic colors | `.secondarySystemBackground`, `.systemGray5`, `.secondary` | All surfaces & secondary text — free dark-mode support |

Rules:
- Orange = "in progress / action". Green = "done / goal met". Never mix roles.
- No custom grays/backgrounds — system semantic colors only (dark mode works for free).

## Typography

| Style | Spec | Usage |
|---|---|---|
| Hero number | `.system(size: 52–72, weight: .bold, design: .rounded)` | Ring grams, onboarding target |
| Screen title | `.largeTitle.bold()` | Navigation titles, onboarding headers |
| Row title | `.headline` / `.body` | List rows, cards |
| Supporting | `.subheadline` / `.caption` + `.secondary` | Timestamps, hints, empty states |

Rules:
- **All numbers use `design: .rounded`** — it's the app's visual signature.
- Grams always rendered as `Int(value.rounded())` + `g` (e.g. `142g`). Never decimals in UI.
- Animate number changes with `.contentTransition(.numericText())`.

## Components

| Component | Spec |
|---|---|
| **Progress ring** | 230×230, stroke 22, round caps, `.systemGray5` track, linear-gradient fill (orange→deep; green→mint when ≥ goal), `-90°` rotated, spring animation (0.6s) on progress |
| **Primary button** | `.borderedProminent` + `.controlSize(.large)` + `.tint(.proteinOrange)`, full-width label |
| **Favorite chip** | VStack(name `.subheadline.bold()`, grams `.caption.secondary`), padding 14×8, `RoundedRectangle(12)` `.secondarySystemBackground`, horizontal scroll row, context menu for delete |
| **Streak badge** | Capsule, orange fill, white `flame.fill` + "N day streak" `.subheadline.bold()` |
| **Selection card** (onboarding goals) | `RoundedRectangle(14)` secondary background, 2pt orange stroke + trailing `checkmark.circle.fill` when selected |
| **Sheet** | `.presentationDetents([.medium, .large])`, NavigationStack inside, Cancel left / bold confirm right |

## Iconography (SF Symbols only)

| Meaning | Symbol |
|---|---|
| App / today | `chart.pie.fill` |
| Streak | `flame.fill` |
| Goal met | `checkmark.circle.fill` (green) |
| Add | `plus.circle.fill` (orange) |
| History | `calendar` |
| Settings | `gearshape.fill` |
| Goals | maintain `heart.fill` · build `dumbbell.fill` · cut `flame.fill` |

## Motion
- Data changes: `withAnimation` spring; ring fills with `.spring(duration: 0.6)`
- Step/screen transitions: `.easeInOut`
- No decorative animation — motion only communicates state change.

## Voice & copy
- Short, coaching, never judgmental: "40g to go", "Goal hit!", "Nothing logged yet — tap a favorite or hit +"
- No medical claims anywhere; Settings footer carries "Not medical advice."

## Layout rules
- Lists: `.insetGrouped`; hero content (ring) in a clear-background row
- Touch targets ≥ 44pt; one primary action per screen, top-right or bottom full-width
- Every list has a designed empty state (text hint minimum)
