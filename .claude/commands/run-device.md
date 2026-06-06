---
description: Build and run TrackProtein on my physical iPhone 13 (USB/Wi-Fi connected)
---

Build and install TrackProtein on my physical iPhone 13. Steps:

1. **Find the device**: `xcrun devicectl list devices` (fall back to `xcrun xctrace list devices`). If no iPhone appears, tell me to plug it in / unlock it / trust this Mac, then stop.
2. **Check signing**: device builds need a team. Check `project.yml` for `DEVELOPMENT_TEAM`. If missing, find one with `security find-identity -v -p codesigning` (Apple Development cert shows the team ID in parentheses) and add to `project.yml` under `settings.base`:
   ```yaml
   DEVELOPMENT_TEAM: <TEAMID>
   ```
   then `xcodegen generate`. If no identity exists, tell me to open Xcode → Settings → Accounts and sign in with my Apple ID first, then stop.
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
5. If launch fails with an untrusted-developer error, tell me: iPhone → Settings → General → VPN & Device Management → trust the developer profile, then relaunch.

Report build/install results plainly. Common failure: free Apple ID provisioning profiles expire after 7 days — fix is just rebuilding with `-allowProvisioningUpdates`.
