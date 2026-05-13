import Foundation
import SwiftData

/// Derives Home-screen state from SwiftData.
///
/// Used by `HomeView` via `@Query`. The actual queries live in the view layer (SwiftData's @Query
/// is a property wrapper that needs to be declared on a View). This file holds derived helpers
/// and sort comparators that are unit-testable in isolation.
enum HomeViewModel {

    /// Sort favorites: lower sortOrder first, then alphabetic by name.
    static func favoriteSort(_ a: ProductItem, _ b: ProductItem) -> Bool {
        if a.sortOrder != b.sortOrder { return a.sortOrder < b.sortOrder }
        return a.name < b.name
    }

    /// Sort recent queries: most recent first.
    static func recentSort(_ a: RecentQuery, _ b: RecentQuery) -> Bool {
        a.queriedAt > b.queriedAt
    }

    /// Truncate to the N most recent.
    static func topRecent(_ queries: [RecentQuery], limit: Int = 10) -> [RecentQuery] {
        Array(queries.sorted(by: recentSort).prefix(limit))
    }
}
