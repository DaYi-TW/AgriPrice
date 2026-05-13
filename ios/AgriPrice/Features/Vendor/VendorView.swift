import SwiftUI
import SwiftData

struct VendorView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = VendorViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Color.pageBackground.ignoresSafeArea()
                if let data = viewModel.resultData {
                    VendorResultsView(
                        data: data,
                        supplyNo: viewModel.supplyNo,
                        supplySub: viewModel.supplySub,
                        onLogout: { viewModel.logout() }
                    )
                } else {
                    ScrollView {
                        VendorLoginForm(viewModel: viewModel) {
                            viewModel.query(context: context)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("成交")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.hydrate(from: context)
            }
        }
    }
}
