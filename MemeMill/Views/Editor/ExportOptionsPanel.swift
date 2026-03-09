import SwiftUI

struct ExportOptionsPanel: View {
    @ObservedObject var exportVM: ExportViewModel
    let source: VideoSource?
    let timeRange: TimeRange
    let onExport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Options")
                .font(.headline)

            // FPS
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("FPS")
                    Spacer()
                    Text("\(exportVM.options.fps)")
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { Double(exportVM.options.fps) },
                        set: { exportVM.options.fps = Int($0) }
                    ),
                    in: 5...30,
                    step: 1
                )
            }

            // Scale
            Picker("Scale", selection: $exportVM.options.scale) {
                ForEach(ResolutionScale.allCases) { scale in
                    Text(scale.rawValue).tag(scale)
                }
            }

            // Quality
            Picker("Quality", selection: $exportVM.options.quality) {
                ForEach(GIFQuality.allCases) { quality in
                    Text(quality.rawValue.capitalized).tag(quality)
                }
            }

            // Speed
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Speed")
                    Spacer()
                    Text(String(format: "%.1fx", exportVM.options.speed))
                        .monospacedDigit()
                }
                Slider(value: $exportVM.options.speed, in: 0.25...4.0, step: 0.25)
            }

            // Duration info
            if timeRange.isValid {
                HStack {
                    Text("Duration")
                    Spacer()
                    Text(String(format: "%.1fs", timeRange.duration))
                        .foregroundColor(.secondary)
                }

                if !timeRange.isWithinGIFLimit {
                    Text("Max GIF duration is 30s")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Divider()

            // Export button
            if exportVM.isExporting {
                VStack(spacing: 8) {
                    ProgressView(value: exportVM.progress)
                    Text(String(format: "Exporting... %.0f%%", exportVM.progress * 100))
                        .font(.caption)
                    Button("Cancel") {
                        exportVM.cancelExport()
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Button(action: onExport) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Export GIF")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(source == nil || !timeRange.isValid || !timeRange.isWithinGIFLimit)
            }

            if let error = exportVM.exportError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(3)
            }

            if exportVM.showExportSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("GIF exported!")
                        .font(.caption)
                }
            }
        }
        .padding()
        .frame(width: 250)
    }
}
