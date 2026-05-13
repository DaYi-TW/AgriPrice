import SwiftUI
import SwiftData

@main
struct AgriPriceApp: App {
    @State private var containerOrError: Result<ModelContainer, Error>

    init() {
        do {
            let container = try ModelContainer(
                for: ProductItem.self,
                    MarketPriceRecord.self,
                    RecentQuery.self,
                    VendorQueryProfile.self
            )
            try Self.seedIfNeeded(container: container)
            _containerOrError = State(initialValue: .success(container))
        } catch {
            _containerOrError = State(initialValue: .failure(error))
        }
    }

    var body: some Scene {
        WindowGroup {
            switch containerOrError {
            case .success(let container):
                AppShell()
                    .modelContainer(container)
                    .preferredColorScheme(.light)
            case .failure(let error):
                ErrorScreen(
                    title: "無法啟動",
                    message: "資料庫初始化失敗。請確認裝置空間足夠後重新啟動 App。\n\n\(error.localizedDescription)"
                )
            }
        }
    }

    /// Seed `ProductItem` rows from `BundledProducts.json` on first launch.
    /// Idempotent: only inserts codes that are not yet in the store.
    private static func seedIfNeeded(container: ModelContainer) throws {
        let context = ModelContext(container)
        let existing = try context.fetch(FetchDescriptor<ProductItem>())
        let existingCodes = Set(existing.map(\.code))

        guard let url = Bundle.main.url(forResource: "BundledProducts", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            // Resource missing in this build configuration; not fatal.
            return
        }

        let seeds = try JSONDecoder().decode([SeedProduct].self, from: data)
        for (index, seed) in seeds.enumerated() where !existingCodes.contains(seed.code) {
            let item = ProductItem(
                code: seed.code,
                name: seed.name,
                category: seed.category,
                isFavorite: false,
                sortOrder: index
            )
            context.insert(item)
        }
        try context.save()
    }

    private struct SeedProduct: Decodable {
        let code: String
        let name: String
        let category: String?
    }
}
