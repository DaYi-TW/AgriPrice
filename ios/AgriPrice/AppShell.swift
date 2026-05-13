import SwiftUI

struct AppShell: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("首頁", systemImage: "house.fill")
                }

            MarketView()
                .tabItem {
                    Label("行情", systemImage: "chart.bar.fill")
                }

            VendorView()
                .tabItem {
                    Label("成交", systemImage: "doc.text.magnifyingglass")
                }

            TrendView()
                .tabItem {
                    Label("趨勢", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .tint(DesignTokens.Color.brandGreen)
    }
}
