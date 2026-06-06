import SwiftUI

struct MainTabView: View {
    let profile: UserProfile

    @State private var selectedTab = 0
    @State private var quickAddRequest = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(profile: profile, quickAddRequest: $quickAddRequest)
                .tabItem { Label("Today", systemImage: "chart.pie.fill") }
                .tag(0)
            HistoryView(profile: profile)
                .tabItem { Label("History", systemImage: "calendar") }
                .tag(1)
            StatsView(profile: profile)
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(2)
            SettingsView(profile: profile)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(.proteinOrange)
        .onOpenURL { url in
            // Widget tap → jump straight to Quick Add.
            guard url.absoluteString == "trackprotein://add" else { return }
            selectedTab = 0
            quickAddRequest = true
        }
    }
}
