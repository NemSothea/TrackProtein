---
name: trackprotein-feature
description: Scaffold or extend a TrackProtein feature (SwiftUI + MVVM + SwiftData). Use when the user asks to "build [feature]", "add [screen]", or "create [component]" for TrackProtein — e.g. widgets, food search, barcode scan, AI logging, stats, paywall.
---

# TrackProtein Feature Builder

Build features following this project's exact conventions. Read `CLAUDE.md` and `PLAN.md` first if not already in context.

## File placement
- New feature → `TrackProtein/Features/<FeatureName>/` containing `<FeatureName>View.swift` + `<FeatureName>ViewModel.swift` (skip the VM only for trivial leaf views like `ProgressRingView`).
- Shared logic → `TrackProtein/Core/Services/` as a pure `enum` with static funcs (pattern: `GoalCalculator`, `StreakCalculator`).
- New @Model → `TrackProtein/Core/Models/`, then register it in `TrackProteinApp.modelContainer(for:)`.
- After ANY file add/remove/move: `xcodegen generate` (the .xcodeproj is generated, never hand-edited).

## Code patterns (copy these, don't invent new ones)
```swift
// ViewModel — @Observable, context passed in, never stored
@Observable
final class FoodSearchViewModel {
    var query = ""
    func log(_ result: FoodResult, context: ModelContext) {
        context.insert(ProteinEntry(grams: result.grams, label: result.name, source: .search))
    }
}

// View — @Query for lists, @State for the VM
struct FoodSearchView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = FoodSearchViewModel()
}

// Enum persisted in a @Model — raw string + computed property (see UserProfile.goalType)
```

## Project specifics
- Logging anything creates a `ProteinEntry` with the right `LogSource` (`.manual/.favorite/.search/.barcode/.ai`).
- Reuse `QuickAddView(entry:)` for editing and `QuickAddView(presetDate:)` for past days — don't build new entry forms.
- Theme: `Color.proteinOrange` accent, green for goal-met, `design: .rounded` for big numbers, grams as `Int(x.rounded())g`.
- Sheets: `.presentationDetents([.medium, .large])` for quick interactions.
- Phase discipline: check `PLAN.md` §2 — if the user asks for a Phase 2/3 feature while Phase 1 is incomplete, build it but mention what Phase 1 items remain.

## Definition of done
1. `xcodegen generate` + simulator build passes (`xcodebuild ... -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`).
2. Empty state handled, dark mode works (use system colors/materials), no force unwraps.
3. New business logic in Core/Services is pure & testable.
4. Update the Phase status line in `CLAUDE.md` if a PLAN.md feature (F-number) is now done.
