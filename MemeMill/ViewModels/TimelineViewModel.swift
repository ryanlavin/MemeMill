import SwiftUI
import AVFoundation

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published var thumbnails: [(time: CMTime, image: NSImage)] = []
    @Published var isGenerating = false

    private let generator: ThumbnailGeneratorProtocol
    private var generationTask: Task<Void, Never>?

    init(generator: ThumbnailGeneratorProtocol) {
        self.generator = generator
    }

    func generateThumbnails(for asset: AVURLAsset, count: Int = 40) {
        generationTask?.cancel()
        isGenerating = true

        generationTask = Task {
            do {
                let results = try await generator.generateThumbnails(
                    from: asset,
                    count: count,
                    height: 60
                )
                if !Task.isCancelled {
                    self.thumbnails = results
                }
            } catch {
                // Silently fail - empty thumbnails is acceptable
            }
            self.isGenerating = false
        }
    }

    func timeForPosition(_ x: CGFloat, totalWidth: CGFloat, duration: Double) -> Double {
        guard totalWidth > 0 else { return 0 }
        let fraction = max(0, min(x / totalWidth, 1.0))
        return fraction * duration
    }

    func positionForTime(_ time: Double, totalWidth: CGFloat, duration: Double) -> CGFloat {
        guard duration > 0 else { return 0 }
        let fraction = max(0, min(time / duration, 1.0))
        return fraction * totalWidth
    }

    func cancel() {
        generationTask?.cancel()
    }
}
