import SwiftUI

struct ProgressOverlay: View {
    let progress: Double
    let message: String
    let onCancel: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: 200)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)

            if let onCancel = onCancel {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}
