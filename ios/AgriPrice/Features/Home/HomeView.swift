import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(filter: #Predicate<ProductItem> { $0.isFavorite == true })
    private var favoritesRaw: [ProductItem]

    @Query(sort: \RecentQuery.queriedAt, order: .reverse)
    private var recentRaw: [RecentQuery]

    @Query private var vendorProfiles: [VendorQueryProfile]

    let switchToTab: (AppTab) -> Void

    init(switchToTab: @escaping (AppTab) -> Void = { _ in }) {
        self.switchToTab = switchToTab
    }

    private var favorites: [ProductItem] {
        favoritesRaw.sorted(by: HomeViewModel.favoriteSort)
    }

    private var recent: [RecentQuery] {
        HomeViewModel.topRecent(recentRaw)
    }

    private var vendorProfile: VendorQueryProfile? { vendorProfiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroCard
                    summaryGrid
                    functionCards
                    favoritesSection
                    recentSection
                    if let profile = vendorProfile {
                        vendorFooterCard(profile)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(DesignTokens.Color.pageBackground)
            .navigationTitle("AgriPrice 農價通")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日焦點")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.85))
            Text("尚無查詢紀錄")
                .font(.title.bold())
                .foregroundStyle(.white)
            Text("選擇品項開始查詢今日各市場行情")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [DesignTokens.Color.brandGreen, DesignTokens.Color.brandGreenLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(DesignTokens.Radius.card)
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryCard(title: "全市場均價", value: "—")
            summaryCard(title: "今日漲跌", value: "—")
            summaryCard(title: "最高市場", value: "—")
            summaryCard(title: "最低市場", value: "—")
        }
    }

    private func summaryCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(DesignTokens.Color.secondaryForeground)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(DesignTokens.Color.foreground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .cornerRadius(DesignTokens.Radius.card)
    }

    private var functionCards: some View {
        HStack(spacing: 12) {
            functionCard(title: "行情查詢", subtitle: "查所有市場", systemImage: "chart.bar.fill")
            functionCard(title: "今日成交", subtitle: "查我的營收", systemImage: "doc.text.magnifyingglass")
        }
    }

    private func functionCard(title: String, subtitle: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(DesignTokens.Color.brandGreen)
                .font(.title2)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(DesignTokens.Color.secondaryForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(DesignTokens.Color.brandTint)
        .cornerRadius(DesignTokens.Radius.card)
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("常用品項")
                .font(.headline)
            if favorites.isEmpty {
                Text("尚未收藏品項,前往行情頁加入")
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.Color.secondaryForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(DesignTokens.Radius.card)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(favorites, id: \.code) { product in
                            chip(text: "\(product.code) \(product.name)")
                        }
                    }
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最近查詢")
                .font(.headline)
            if recent.isEmpty {
                Text("尚無查詢紀錄")
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.Color.secondaryForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(DesignTokens.Radius.card)
            } else {
                ForEach(recent, id: \.queriedAt) { query in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(query.productCode) \(query.productName)")
                                .font(.subheadline.bold())
                            Text(dateRangeLabel(query.startDate, query.endDate))
                                .font(.caption)
                                .foregroundStyle(DesignTokens.Color.secondaryForeground)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(DesignTokens.Color.secondaryForeground)
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(DesignTokens.Radius.card)
                }
            }
        }
    }

    private func vendorFooterCard(_ profile: VendorQueryProfile) -> some View {
        Button(action: { switchToTab(.vendor) }) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundStyle(DesignTokens.Color.brandGreen)
                VStack(alignment: .leading, spacing: 2) {
                    Text("上次查詢成交")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Color.secondaryForeground)
                    Text("\(profile.supplierCode)-\(profile.subCode) (\(timeLabel(profile.updatedAt)))")
                        .font(.subheadline.bold())
                        .foregroundStyle(DesignTokens.Color.foreground)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(DesignTokens.Color.secondaryForeground)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(DesignTokens.Radius.card)
        }
        .buttonStyle(.plain)
    }

    private func timeLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }

    private func chip(text: String) -> some View {
        Text(text)
            .font(.subheadline.bold())
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(DesignTokens.Color.brandTint)
            .foregroundStyle(DesignTokens.Color.brandGreen)
            .cornerRadius(DesignTokens.Radius.chip)
    }

    private func dateRangeLabel(_ start: Date, _ end: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MM/dd"
        if Calendar.current.isDate(start, inSameDayAs: end) {
            return fmt.string(from: start)
        }
        return "\(fmt.string(from: start)) ～ \(fmt.string(from: end))"
    }
}
