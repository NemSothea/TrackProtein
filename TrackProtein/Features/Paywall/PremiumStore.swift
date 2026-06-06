import Foundation
import Observation
import StoreKit

/// StoreKit 2 wrapper — products, purchases, and the premium entitlement.
/// Locally testable via TrackProtein.storekit (no App Store Connect needed).
@MainActor
@Observable
final class PremiumStore {
    static let shared = PremiumStore()

    static let monthlyID = "com.sothea.trackprotein.premium.monthly"
    static let yearlyID = "com.sothea.trackprotein.premium.yearly"
    static let lifetimeID = "com.sothea.trackprotein.premium.lifetime"
    private static let allIDs = [monthlyID, yearlyID, lifetimeID]

    private(set) var products: [Product] = []
    private(set) var purchasedIDs: Set<String> = []
    private(set) var loadFailed = false

    #if DEBUG
    /// Dev-only unlock for device testing (StoreKit config only applies to Xcode-launched runs).
    var debugUnlocked = UserDefaults.standard.bool(forKey: "debugPremium") {
        didSet { UserDefaults.standard.set(debugUnlocked, forKey: "debugPremium") }
    }
    #endif

    var isPremium: Bool {
        #if DEBUG
        if debugUnlocked { return true }
        #endif
        return !purchasedIDs.isEmpty
    }

    private var updatesTask: Task<Void, Never>?

    private init() {
        // Keep entitlements current for purchases made outside the app (App Store, family sharing).
        updatesTask = Task { await listenForTransactions() }
    }

    func load() async {
        if products.isEmpty {
            do {
                products = try await Product.products(for: Self.allIDs)
                    .sorted { $0.price < $1.price }
                loadFailed = products.isEmpty
            } catch {
                loadFailed = true
            }
        }
        await refreshEntitlements()
    }

    func purchase(_ product: Product) async {
        guard let result = try? await product.purchase() else { return }
        if case .success(let verification) = result,
           case .verified(let transaction) = verification {
            await transaction.finish()
            await refreshEntitlements()
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    private func refreshEntitlements() async {
        var ids: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                ids.insert(transaction.productID)
            }
        }
        purchasedIDs = ids
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                await refreshEntitlements()
            }
        }
    }
}
