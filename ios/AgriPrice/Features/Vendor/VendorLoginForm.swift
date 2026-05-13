import SwiftUI

struct VendorLoginForm: View {
    @Bindable var viewModel: VendorViewModel
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                field(title: "供應代號", value: $viewModel.supplyNo, secure: false, keyboard: .asciiCapable)
                field(title: "小代號",   value: $viewModel.supplySub, secure: false, keyboard: .asciiCapable)
                field(title: "密碼",     value: $viewModel.password,  secure: true,  keyboard: .asciiCapable)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(DesignTokens.Radius.card)

            rememberToggle

            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }

            Button(action: onSubmit) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    }
                    Text(viewModel.isLoading ? "查詢中…" : "查詢")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(viewModel.canSubmit ? DesignTokens.Color.brandGreen : Color.gray.opacity(0.5))
                .cornerRadius(DesignTokens.Radius.card)
            }
            .disabled(!viewModel.canSubmit || viewModel.isLoading)

            Spacer(minLength: 0)
        }
    }

    private func field(title: String, value: Binding<String>, secure: Bool, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(DesignTokens.Color.secondaryForeground)
            Group {
                if secure {
                    SecureField("", text: value)
                } else {
                    TextField("", text: value)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .keyboardType(keyboard)
            .padding(10)
            .background(DesignTokens.Color.pageBackground)
            .cornerRadius(8)
        }
    }

    private var rememberToggle: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: Binding(
                get: { viewModel.rememberCredential },
                set: { viewModel.setRememberCredential($0) }
            )) {
                Text("記住密碼(Face ID / Touch ID)")
                    .font(.subheadline)
            }
            .tint(DesignTokens.Color.brandGreen)
            if let toggleError = viewModel.rememberToggleError {
                Text(toggleError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(DesignTokens.Radius.card)
    }
}
