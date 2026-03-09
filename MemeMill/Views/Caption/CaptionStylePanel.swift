import SwiftUI

struct CaptionStylePanel: View {
    @Binding var style: CaptionStyle
    let availableFonts: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Font picker
            Picker("Font", selection: $style.fontName) {
                ForEach(availableFonts, id: \.self) { font in
                    Text(font).tag(font)
                }
            }

            // Font size
            HStack {
                Text("Size")
                Spacer()
                Text("\(Int(style.fontSize))")
                    .monospacedDigit()
            }
            Slider(value: $style.fontSize, in: 16...96, step: 2)

            // Text color
            ColorPicker("Text Color", selection: Binding(
                get: { Color(nsColor: NSColor(hex: style.textColorHex) ?? .white) },
                set: { newColor in
                    style.textColorHex = NSColor(newColor).hexString
                }
            ))

            // Stroke color
            ColorPicker("Stroke Color", selection: Binding(
                get: { Color(nsColor: NSColor(hex: style.strokeColorHex) ?? .black) },
                set: { newColor in
                    style.strokeColorHex = NSColor(newColor).hexString
                }
            ))

            // Stroke width
            HStack {
                Text("Stroke")
                Spacer()
                Text(String(format: "%.1f", style.strokeWidth))
                    .monospacedDigit()
            }
            Slider(value: $style.strokeWidth, in: 0...10, step: 0.5)
        }
    }
}
