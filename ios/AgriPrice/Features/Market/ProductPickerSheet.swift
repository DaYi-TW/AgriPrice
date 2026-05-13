import SwiftUI
import SwiftData

struct ProductPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query private var products: [ProductItem]

    let onPick: (ProductItem) -> Void

    private var sorted: [ProductItem] {
        products.sorted { a, b in
            if a.isFavorite != b.isFavorite { return a.isFavorite && !b.isFavorite }
            if a.sortOrder != b.sortOrder { return a.sortOrder < b.sortOrder }
            return a.name < b.name
        }
    }

    var body: some View {
        NavigationStack {
            List(sorted, id: \.code) { product in
                HStack(spacing: 12) {
                    Button {
                        product.isFavorite.toggle()
                        product.updatedAt = .now
                        try? context.save()
                    } label: {
                        Image(systemName: product.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(product.isFavorite
                                             ? DesignTokens.Color.brandGreen
                                             : DesignTokens.Color.secondaryForeground)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.name)
                            .font(.body)
                        Text(product.code)
                            .font(.caption)
                            .foregroundStyle(DesignTokens.Color.secondaryForeground)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onPick(product)
                    dismiss()
                }
            }
            .listStyle(.plain)
            .navigationTitle("選擇品項")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}
