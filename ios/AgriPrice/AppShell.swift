import SwiftUI

enum AppTab: Hashable {
    case home, market, vendor, trend
}

struct AppShell: View {
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView(switchToTab: { selection = $0 })
                .tabItem {
                    Label("首頁", systemImage: "house.fill")
                }
                .tag(AppTab.home)

            MarketView()
                .tabItem {
                    Label("行情", systemImage: "chart.bar.fill")
                }
                .tag(AppTab.market)

            VendorView()
                .tabItem {
                    Label("成交", systemImage: "doc.text.magnifyingglass")
                }
                .tag(AppTab.vendor)

            TrendView()
                .tabItem {
                    Label("趨勢", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(AppTab.trend)
        }
        .tint(DesignTokens.Color.brandGreen)
    }
}
