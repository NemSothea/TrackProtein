import Foundation
import SwiftData

/// Builds the ModelContainer in the App Group container so the app and widgets share one store.
enum SharedStore {
    static let appGroupID = "group.com.sothea.trackprotein"
    static let schema = Schema([UserProfile.self, ProteinEntry.self, FavoriteFood.self])

    static func makeContainer() -> ModelContainer {
        do {
            let config = ModelConfiguration(
                schema: schema,
                groupContainer: .identifier(appGroupID),
                cloudKitDatabase: .none
            )
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Fall back to the default store so the app still runs without the group entitlement
            // (e.g. previews); widgets will show the placeholder state in that case.
            do {
                let config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }
}
