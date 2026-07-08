---
name: trackprotein-run-sim
description: Build, run, and visually verify TrackProtein in the iOS Simulator. Use when the user asks to "run it", "run/build in the simulator", "launch the app", "check it on screen", "screenshot the app", or asks to verify a specific screen or flow visually. Also invocable as /trackprotein-run-sim.
---

# TrackProtein — Run & Verify in Simulator

Goal: get the current code running in the Simulator and confirm visually what's on
screen — not just that it compiles.

## Preferred path: delegate to the `ios-simulator-verifier` agent
Spawn the `ios-simulator-verifier` agent so the (verbose) build + install output stays out
of the main conversation. Pass it exactly these parameters:

- **project root:** `/Users/sothea007/Desktop/TrackProtein`
- **project:** `TrackProtein.xcodeproj`
- **scheme:** `TrackProtein`
- **bundle id:** `com.sothea.trackprotein`
- **simulator:** `iPhone 17 Pro`
- **pre-step:** run `xcodegen generate` first (keeps the generated project in sync).
- If `$ARGUMENTS` (or the user's request) names a screen/flow, tell the agent to drive to it
  and screenshot that state. For onboarding, tell it to **fresh-install** first
  (`xcrun simctl uninstall "iPhone 17 Pro" com.sothea.trackprotein`).

Relay the agent's verdict + what it saw on screen. If it reports a crash/blank/wrong view,
that's the finding — surface it, don't paper over it.

## Manual fallback (if the agent is unavailable)
1. `xcodegen generate`, then build:
   ```bash
   xcodebuild -project TrackProtein.xcodeproj -scheme TrackProtein \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
   ```
2. Boot + **wait** (boot is flaky right after `simctl boot` — always wait):
   ```bash
   xcrun simctl boot "iPhone 17 Pro" || true
   open -a Simulator
   xcrun simctl bootstatus "iPhone 17 Pro" -b
   ```
3. Install & launch (app path is under DerivedData
   `Build/Products/Debug-iphonesimulator/TrackProtein.app`; find it with
   `xcodebuild -showBuildSettings | grep BUILT_PRODUCTS_DIR` if unsure):
   ```bash
   xcrun simctl install "iPhone 17 Pro" <path>/TrackProtein.app
   xcrun simctl launch com.sothea.trackprotein
   ```
4. Screenshot and **Read it** — describe what's actually on screen:
   ```bash
   xcrun simctl io "iPhone 17 Pro" screenshot /tmp/trackprotein.png
   ```
   If it's wrong (crash, blank, wrong view), check logs:
   ```bash
   xcrun simctl spawn "iPhone 17 Pro" log show --last 2m --predicate 'process == "TrackProtein"' | tail -50
   ```
5. Re-test onboarding from scratch: uninstall first (see pre-step above).
