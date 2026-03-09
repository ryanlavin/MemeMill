import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct VideoEditorView: View {
    @EnvironmentObject var preferences: UserPreferences
    @StateObject private var editorVM: VideoEditorViewModel
    @StateObject private var timelineVM: TimelineViewModel
    @StateObject private var exportVM: ExportViewModel
    @State private var isDragOver = false

    private let templateStore: TemplateStore

    init() {
        let ffmpeg = FFmpegService()
        let videoLoader = VideoLoaderService(ffmpeg: ffmpeg)
        let thumbnailGen = ThumbnailGenerator()
        let exporter = GIFExportService(ffmpeg: ffmpeg)
        let prefs = UserPreferences()
        let store = TemplateStore(outputDirectory: prefs.outputDirectory)

        _editorVM = StateObject(wrappedValue: VideoEditorViewModel(videoLoader: videoLoader))
        _timelineVM = StateObject(wrappedValue: TimelineViewModel(generator: thumbnailGen))
        _exportVM = StateObject(wrappedValue: ExportViewModel(
            exporter: exporter,
            templateStore: store,
            preferences: prefs
        ))
        self.templateStore = store
    }

    var body: some View {
        HSplitView {
            // Main editor area
            VStack(spacing: 0) {
                if editorVM.isLoading {
                    ProgressView("Loading video...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = editorVM.loadError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.secondary)
                        Button("Try Again") {
                            showFilePicker()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if editorVM.videoSource != nil {
                    videoEditorContent
                } else {
                    DropZoneView(isDragOver: $isDragOver) { url in
                        Task {
                            await loadVideo(url)
                        }
                    }
                }
            }
            .frame(minWidth: 600)

            // Export options sidebar
            if editorVM.videoSource != nil {
                ExportOptionsPanel(
                    exportVM: exportVM,
                    source: editorVM.videoSource,
                    timeRange: editorVM.timeRange,
                    onExport: {
                        guard let source = editorVM.videoSource else { return }
                        exportVM.exportGIF(from: source, timeRange: editorVM.timeRange)
                    }
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openVideoFile)) { notification in
            if let url = notification.object as? URL {
                Task { await loadVideo(url) }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFilePicker)) { _ in
            showFilePicker()
        }
    }

    // MARK: - Video Editor Content

    private var videoEditorContent: some View {
        VStack(spacing: 8) {
            // Video player
            VideoPlayerView(player: editorVM.player)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Transport controls
            transportControls

            // Timeline
            TimelineView(
                timelineVM: timelineVM,
                currentTime: $editorVM.currentTime,
                timeRange: $editorVM.timeRange,
                duration: editorVM.videoSource?.durationSeconds ?? 0,
                onSeek: { time in
                    editorVM.seek(to: time)
                }
            )
            .padding(.horizontal)

            // Time display
            timeDisplay
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
    }

    private var transportControls: some View {
        HStack(spacing: 16) {
            // Step backward
            Button(action: { editorVM.stepFrame(forward: false) }) {
                Image(systemName: "backward.frame")
            }
            .keyboardShortcut(.leftArrow, modifiers: [])

            // Play/Pause
            Button(action: { editorVM.togglePlayPause() }) {
                Image(systemName: editorVM.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
            }
            .keyboardShortcut(.space, modifiers: [])

            // Step forward
            Button(action: { editorVM.stepFrame(forward: true) }) {
                Image(systemName: "forward.frame")
            }
            .keyboardShortcut(.rightArrow, modifiers: [])

            Divider().frame(height: 20)

            // Set In point
            Button(action: { editorVM.setStartMarker() }) {
                HStack(spacing: 4) {
                    Image(systemName: "bracket.square")
                    Text("In")
                }
            }
            .help("Set start point (I)")

            // Set Out point
            Button(action: { editorVM.setEndMarker() }) {
                HStack(spacing: 4) {
                    Text("Out")
                    Image(systemName: "bracket.square")
                }
            }
            .help("Set end point (O)")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal)
    }

    private var timeDisplay: some View {
        HStack {
            Text(formatTime(editorVM.currentTime))
                .monospacedDigit()
                .font(.caption)

            Spacer()

            HStack(spacing: 4) {
                Text("In: \(formatTime(editorVM.timeRange.start))")
                Text("-")
                Text("Out: \(formatTime(editorVM.timeRange.end))")
                Text("(\(String(format: "%.1fs", editorVM.timeRange.duration)))")
            }
            .monospacedDigit()
            .font(.caption)
            .foregroundColor(.secondary)

            Spacer()

            if let source = editorVM.videoSource {
                Text(formatTime(source.durationSeconds))
                    .monospacedDigit()
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func loadVideo(_ url: URL) async {
        await editorVM.loadVideo(from: url)
        if let source = editorVM.videoSource {
            let asset = AVURLAsset(url: source.playableURL)
            timelineVM.generateThumbnails(for: asset)
        }
    }

    private func showFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie, .avi]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            Task { await loadVideo(url) }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let frac = Int((seconds.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", mins, secs, frac)
    }
}
