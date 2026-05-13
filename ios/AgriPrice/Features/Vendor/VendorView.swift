import SwiftUI

/// Stub for feature 003. Replaced by feature 002.
struct VendorView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignTokens.Color.brandGreen)
                Text("今日成交")
                    .font(.title2.bold())
                Text("即將推出(feature 002)")
                    .foregroundStyle(DesignTokens.Color.secondaryForeground)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignTokens.Color.pageBackground)
            .navigationTitle("成交")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
