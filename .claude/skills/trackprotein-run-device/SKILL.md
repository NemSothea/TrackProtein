---
name: trackprotein-run-device
description: Build and run TrackProtein on the user's physical iPhone (iPhone 13, USB/Wi-Fi connected). Use when the user asks to "run on my iPhone/phone/device", "install on my phone", "test on real hardware", or "build to device". Also invocable as /trackprotein-run-device.
---

# TrackProtein — Run on Physical iPhone

Build and install on the user's real iPhone 13. This stays in the main conversation because
signing/trust steps often need a round-trip with the user.

1. **Find the device**: `xcrun devicectl list devices` (fall back to
   `xcrun xctrace list devices`). If no iPhone appears, tell the user to plug it in / unlock it
   / trust this Mac, then stop.
2. **Check signing**: device builds need a team. Check `project.yml` for `DEVELOPMENT_TEAM`.
   If missing, find one with `security find-identity -v -p codesigning` (an Apple Development
   cert shows the team ID in parentheses) and add it to `project.yml` under `settings.base`:
   ```yaml
   DEVELOPMENT_TEAM: <TEAMID>
   ```
   then `xcodegen generate`. If no identity exists, tell the user to open Xcode → Settings →
   Accounts and sign in with their Apple ID first, then stop.
3. **Build**:
   ```bash
   xcodebuild -project TrackProtein.xcodeproj -scheme TrackProtein \
     -destination 'platform=iOS,name=<device name>' \
     -allowProvisioningUpdates build
   ```
4. **Install & launch**:
   ```bash
   xcrun devicectl device install app --device <UDID> <path to TrackProtein.app from DerivedData Debug-iphoneos>
   xcrun devicectl device process launch --device <UDID> com.sothea.trackprotein
   ```
5. If launch fails with an untrusted-developer error, tell the user: iPhone → Settings →
   General → VPN & Device Management → trust the developer profile, then relaunch.

Report build/install results plainly. Common failure: free Apple ID provisioning profiles
expire after 7 days — the fix is just rebuilding with `-allowProvisioningUpdates`.
