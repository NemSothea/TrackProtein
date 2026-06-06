---
description: Build, run, and screenshot TrackProtein in the iOS Simulator
---

Build and run TrackProtein in the Simulator, then verify it visually:

1. `xcodegen generate` (cheap, keeps project in sync) then build:
   ```bash
   xcodebuild -project TrackProtein.xcodeproj -scheme TrackProtein \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
   ```
2. Boot + wait until ready (boot is flaky right after `simctl boot` — always wait):
   ```bash
   xcrun simctl boot "iPhone 17 Pro" || true
   open -a Simulator
   xcrun simctl bootstatus "iPhone 17 Pro" -b
   ```
3. Install & launch (app path is under DerivedData `Build/Products/Debug-iphonesimulator/TrackProtein.app` — find it with `xcodebuild -showBuildSettings | grep BUILT_PRODUCTS_DIR` if unsure):
   ```bash
   xcrun simctl install "iPhone 17 Pro" <path>/TrackProtein.app
   xcrun simctl launch com.sothea.trackprotein # on "iPhone 17 Pro"
   ```
4. Screenshot and READ it:
   ```bash
   xcrun simctl io "iPhone 17 Pro" screenshot /tmp/trackprotein.png
   ```
   Open the screenshot with the Read tool and describe what's actually on screen. If it's not what's expected (crash, blank screen, wrong view), check logs:
   ```bash
   xcrun simctl spawn "iPhone 17 Pro" log show --last 2m --predicate 'process == "TrackProtein"' | tail -50
   ```
5. To reset to a fresh-install state (re-test onboarding): `xcrun simctl uninstall "iPhone 17 Pro" com.sothea.trackprotein` first.

$ARGUMENTS may name a specific screen/flow to verify — if so, drive to it (fresh install for onboarding) and screenshot that state.
