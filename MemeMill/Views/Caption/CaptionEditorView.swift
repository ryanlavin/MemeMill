import SwiftUI

struct CaptionEditorView: View {
    let sourceTemplate: GIFTemplate
    let templateStore: TemplateStore
    @Environment(\.dismiss) private var dismiss

    @State private var topText = ""
    @State private var bottomText = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Caption")
                .font(.title2)

            // Preview placeholder
            AnimatedGIFView(url: sourceTemplate.fileURL)
                .frame(maxWidth: 400, maxHeight: 300)
                .cornerRadius(8)
                .overlay(alignment: .top) {
                    if !topText.isEmpty {
                        Text(topText.uppercased())
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                            .padding(.top, 8)
                    }
                }
                .overlay(alignment: .bottom) {
                    if !bottomText.isEmpty {
                        Text(bottomText.uppercased())
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                            .padding(.bottom, 8)
                    }
                }

            // Caption inputs
            TextField("Top text", text: $topText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 400)

            TextField("Bottom text", text: $bottomText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 400)

            // Actions
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)

                Button("Export Captioned GIF") {
                    exportCaptioned()
                }
                .buttonStyle(.borderedProminent)
                .disabled(topText.isEmpty && bottomText.isEmpty)
            }
        }
        .padding(24)
        .frame(minWidth: 500, minHeight: 500)
    }

    private func exportCaptioned() {
        let layout = CaptionLayout(
            topText: topText,
            bottomText: bottomText,
            topStyle: .memeDefault,
            bottomStyle: .memeDefault
        )
        let renderer = CaptionRenderer()
        let outputURL = sourceTemplate.fileURL.deletingLastPathComponent()
            .appendingPathComponent("captioned_\(sourceTemplate.fileName)")

        do {
            try renderer.renderCaptions(
                on: sourceTemplate.fileURL,
                layout: layout,
                outputURL: outputURL,
                progressHandler: nil
            )
            Task {
                await templateStore.refresh()
            }
            dismiss()
        } catch {
            // Handle error
        }
    }
}
