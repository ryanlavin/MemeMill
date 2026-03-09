import SwiftUI

struct GIFThumbnailView: View {
    let template: GIFTemplate
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            // GIF preview
            AnimatedGIFView(url: template.fileURL)
                .frame(height: 120)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color.accentColor : Color.clear,
                            lineWidth: 3
                        )
                )

            // File name
            Text(template.fileName)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)

            // Size
            Text(template.fileSizeFormatted)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(4)
    }
}
