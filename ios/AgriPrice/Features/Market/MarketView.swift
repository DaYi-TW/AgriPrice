import SwiftUI

/// Stub for feature 003. Replaced by feature 001.
struct MarketView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignTokens.Color.brandGreen)
                Text("市場行情")
                    .font(.title2.bold())
                Text("即將推出(feature 001)")
                    .foregroundStyle(DesignTokens.Color.secondaryForeground)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignTokens.Color.pageBackground)
            .navigationTitle("行情")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
