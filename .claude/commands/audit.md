---
description: Audit the codebase against PLAN.md — phase progress, gaps, App Store readiness
---

Audit the TrackProtein project against `PLAN.md`. Do all of the following:

1. **Phase progress**: Read `PLAN.md` §2 (Feature Requirements). For the current phase, check each feature (F1, F2, …) against the actual code in `TrackProtein/`. Mark each: ✅ done / 🟡 partial / ❌ missing. Be evidence-based — cite the file that implements it or state what's absent.
2. **Build health**: Run `xcodegen generate` and a simulator build (`xcodebuild -project TrackProtein.xcodeproj -scheme TrackProtein -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`). Report errors/warnings.
3. **Architecture drift**: Check the conventions in `CLAUDE.md` are being followed (MVVM with @Observable, raw-value enum storage, no stray dependencies, files in the right feature folders).
4. **App Store readiness** (PLAN.md §5 checklist): privacy strings, disclaimers, restore-purchases (once StoreKit exists), launch screen, app icon present.
5. **Risks**: anything that will bite later — force unwraps, missing empty states, hardcoded strings that should be localized, data-loss paths.

Output a concise report: phase scorecard table, top 3 priorities to do next, and any red flags. Update nothing — this is read-only.
