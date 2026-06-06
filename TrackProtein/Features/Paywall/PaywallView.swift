import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    private var store: PremiumStore { .shared }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    hero
                    features
                    productButtons

                    Button("Restore Purchases") {
                        Task { await store.restore() }
                    }
                    .font(.subheadline)

                    #if DEBUG
                    Toggle("Dev unlock (DEBUG only)", isOn: Binding(
                        get: { store.debugUnlocked },
                        set: { store.debugUnlocked = $0 }
                    ))
                    .font(.caption)
                    .padding(.horizontal)
                    #endif

                    Text("Subscriptions renew automatically until cancelled in App Store settings. Lifetime is a one-time purchase.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await store.load() }
            .onChange(of: store.isPremium) { _, premium in
                if premium { dismiss() }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 52))
                .foregroundStyle(Color.proteinOrange)
            Text("TrackProtein Premium")
                .font(.title.bold())
            Text("Log smarter. See further.")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow("camera.viewfinder", "AI photo logging", "Snap a meal — Claude estimates the protein")
            featureRow("text.bubble", "Describe to log", "\u{201C}2 eggs and a shake\u{201D} → logged")
            featureRow("chart.bar.fill", "Stats & insights", "Weekly trends, averages, top protein sources")
            featureRow("square.and.arrow.up", "CSV export", "Your data, portable")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private func featureRow(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.proteinOrange)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.subheadline.bold())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var productButtons: some View {
        if store.products.isEmpty {
            if store.loadFailed {
                Text("Purchases are unavailable right now.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        } else {
            VStack(spacing: 10) {
                ForEach(store.products, id: \.id) { product in
                    productButton(product)
                }
            }
        }
    }

    private func productButton(_ product: Product) -> some View {
        let isYearly = product.id == PremiumStore.yearlyID
        return Button {
            Task { await store.purchase(product) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(product.displayName).bold()
                    if isYearly {
                        Text("Best value")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.proteinOrange)
                    }
                }
                Spacer()
                Text(product.displayPrice).bold()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isYearly ? Color.proteinOrange : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
}
