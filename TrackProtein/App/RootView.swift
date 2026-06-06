import SwiftUI
import SwiftData

/// Routes to onboarding until a profile exists, then to the main app.
struct RootView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first {
                MainTabView(profile: profile)
            } else {
                OnboardingView()
            }
        }
        .task { await PremiumStore.shared.load() }
    }
}
