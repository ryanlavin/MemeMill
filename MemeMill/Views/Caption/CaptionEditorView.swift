import SwiftUI

struct CaptionEditorView: View {
    @StateObject private var viewModel: CaptionEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editingTopStyle = false
    @State private var editingBottomStyle = false

    init(sourceTemplate: GIFTemplate, templateStore: TemplateStore) {
        _viewModel = StateObject(wrappedValue: CaptionEditorViewModel(
            sourceTemplate: sourceTemplate,
            captionRenderer: CaptionRenderer(),
            templateStore: templateStore
        ))
    }

    var body: some View {
        HStack(spacing: 0) {
            // Preview panel
            VStack(spacing: 16) {
                Text("Caption Preview")
                    .font(.headline)

                // GIF with text overlays
                ZStack {
                    AnimatedGIFView(url: viewModel.sourceTemplate.fileURL)
                        .frame(maxWidth: 500, maxHeight: 350)

                    // Top text preview
                    VStack {
                        if !viewModel.layout.topText.isEmpty {
                            memeText(viewModel.layout.topText, style: viewModel.layout.topStyle)
                        }
                        Spacer()
                        if !viewModel.layout.bottomText.isEmpty {
                            memeText(viewModel.layout.bottomText, style: viewModel.layout.bottomStyle)
                        }
                    }
                    .padding(8)
                }
                .cornerRadius(8)
                .frame(maxWidth: 500, maxHeight: 350)

                if viewModel.isRendering {
                    VStack(spacing: 8) {
                        ProgressView(value: viewModel.renderProgress)
                            .frame(width: 200)
                        Text("Rendering...")
                            .font(.caption)
                    }
                }

                if viewModel.renderSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Captioned GIF saved!")
                    }
                }

                if let error = viewModel.renderError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()

            Divider()

            // Controls panel
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Caption Text")
                        .font(.headline)

                    // Top text
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Top Text")
                            .font(.subheadline)
                        TextField("Enter top text...", text: $viewModel.layout.topText)
                            .textFieldStyle(.roundedBorder)

                        DisclosureGroup("Top Style", isExpanded: $editingTopStyle) {
                            CaptionStylePanel(
                                style: $viewModel.layout.topStyle,
                                availableFonts: viewModel.availableFonts()
                            )
                        }
                    }

                    Divider()

                    // Bottom text
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bottom Text")
                            .font(.subheadline)
                        TextField("Enter bottom text...", text: $viewModel.layout.bottomText)
                            .textFieldStyle(.roundedBorder)

                        DisclosureGroup("Bottom Style", isExpanded: $editingBottomStyle) {
                            CaptionStylePanel(
                                style: $viewModel.layout.bottomStyle,
                                availableFonts: viewModel.availableFonts()
                            )
                        }
                    }

                    Divider()

                    // Actions
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button("Export Captioned GIF") {
                            Task {
                                await viewModel.renderCaptionedGIF()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.layout.hasContent || viewModel.isRendering)
                    }
                }
                .padding()
            }
            .frame(width: 300)
        }
        .frame(minWidth: 800, minHeight: 500)
    }

    // MARK: - Meme Text Overlay

    private func memeText(_ text: String, style: CaptionStyle) -> some View {
        Text(text.uppercased())
            .font(.custom(style.fontName, size: style.fontSize * 0.5))
            .foregroundColor(Color(nsColor: NSColor(hex: style.textColorHex) ?? .white))
            .shadow(
                color: Color(nsColor: NSColor(hex: style.strokeColorHex) ?? .black),
                radius: 0,
                x: style.strokeWidth * 0.3,
                y: style.strokeWidth * 0.3
            )
            .shadow(
                color: Color(nsColor: NSColor(hex: style.strokeColorHex) ?? .black),
                radius: 0,
                x: -style.strokeWidth * 0.3,
                y: -style.strokeWidth * 0.3
            )
            .multilineTextAlignment(.center)
            .lineLimit(3)
    }
}
