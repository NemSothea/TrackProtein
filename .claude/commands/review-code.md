---
description: Review recent/changed Swift code for bugs, MVVM violations, and SwiftUI/SwiftData pitfalls
---

Review the TrackProtein Swift code (changed files if git history exists; otherwise the files I name, or the whole `TrackProtein/` source if neither). Focus on findings that matter — no style nitpicks. Check for:

**Correctness**
- SwiftData pitfalls: `@Query` predicates captured at init, deleting from filtered arrays with wrong indices, missing `@Bindable` on @Model bindings, context saves on wrong thread
- Date/calendar bugs: timezone, day-boundary (start-of-day) logic, streak edge cases (empty data, gaps, today unfinished)
- Force unwraps, array index assumptions, division by zero (e.g. target = 0)
- State bugs: sheets not resetting, stale @State, edit-vs-add mode confusion

**Architecture (per CLAUDE.md)**
- Business logic in Views that belongs in ViewModels or Core/Services
- ViewModels storing ModelContext instead of receiving it as a parameter
- Duplicated logic that already exists in GoalCalculator/StreakCalculator/extensions

**UX & polish**
- Missing empty/error states, missing animations on data changes, inaccessible touch targets, text that won't fit large Dynamic Type

For each finding: severity (🔴 bug / 🟡 should-fix / 🔵 suggestion), `file:line`, what's wrong, and the concrete fix. End with a verdict: safe to ship Phase 1 or not. Then ask if I want the fixes applied.
