import SwiftUI
import AVFoundation
import Combine

@MainActor
final class VideoEditorViewModel: ObservableObject {
    @Published var videoSource: VideoSource?
    @Published var player: AVPlayer?
    @Published var isLoading = false
    @Published var loadError: String?
    @Published var currentTime: Double = 0.0
    @Published var timeRange = TimeRange(start: 0, end: 5)
    @Published var isPlaying = false

    private let videoLoader: VideoLoaderProtocol
    private var timeObserver: Any?

    init(videoLoader: VideoLoaderProtocol) {
        self.videoLoader = videoLoader
    }

    func loadVideo(from url: URL) async {
        isLoading = true
        loadError = nil

        do {
            let source = try await videoLoader.load(from: url)
            self.videoSource = source
            let newPlayer = AVPlayer(url: source.playableURL)
            self.player = newPlayer
            self.timeRange = TimeRange(
                start: 0,
                end: min(5.0, source.durationSeconds)
            )
            self.currentTime = 0
            setupTimeObserver(player: newPlayer)
        } catch {
            self.loadError = error.localizedDescription
        }

        isLoading = false
    }

    func play() {
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func togglePlayPause() {
        if isPlaying { pause() } else { play() }
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
    }

    func setStartMarker() {
        setStartMarker(at: currentTime)
    }

    func setEndMarker() {
        setEndMarker(at: currentTime)
    }

    func setStartMarker(at time: Double) {
        var newRange = timeRange
        newRange.start = time
        if newRange.start >= newRange.end {
            newRange.end = min(time + 1.0, videoSource?.durationSeconds ?? time + 1.0)
        }
        timeRange = newRange.clamped(to: videoSource?.durationSeconds ?? 0)
    }

    func setEndMarker(at time: Double) {
        var newRange = timeRange
        newRange.end = time
        if newRange.end <= newRange.start {
            newRange.start = max(0, time - 1.0)
        }
        timeRange = newRange.clamped(to: videoSource?.durationSeconds ?? 0)
    }

    func stepFrame(forward: Bool) {
        guard let source = videoSource else { return }
        let frameInterval = 1.0 / Double(source.frameRate)
        let newTime = forward
            ? min(currentTime + frameInterval, source.durationSeconds)
            : max(currentTime - frameInterval, 0)
        seek(to: newTime)
    }

    private func setupTimeObserver(player: AVPlayer) {
        if let observer = timeObserver {
            self.player?.removeTimeObserver(observer)
        }
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                self?.currentTime = CMTimeGetSeconds(time)
            }
        }
    }

    func cleanup() {
        videoLoader.cleanupTemporaryFiles()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
}
