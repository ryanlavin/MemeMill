import AVFoundation
import AppKit

final class ThumbnailGenerator: ThumbnailGeneratorProtocol {
    func generateThumbnails(
        from asset: AVURLAsset,
        count: Int,
        height: CGFloat
    ) async throws -> [(time: CMTime, image: NSImage)] {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.maximumSize = CGSize(width: 0, height: height)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.5, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.5, preferredTimescale: 600)

        let duration = try await asset.load(.duration)
        let totalSeconds = CMTimeGetSeconds(duration)
        guard totalSeconds > 0 else { return [] }

        let interval = totalSeconds / Double(count)
        let times: [CMTime] = (0..<count).map { i in
            CMTime(seconds: Double(i) * interval, preferredTimescale: 600)
        }

        var results: [(time: CMTime, image: NSImage)] = []
        for await result in generator.images(for: times) {
            switch result {
            case .success(let requestedTime, let cgImage, _):
                let nsImage = NSImage(
                    cgImage: cgImage,
                    size: NSSize(
                        width: CGFloat(cgImage.width),
                        height: CGFloat(cgImage.height)
                    )
                )
                results.append((time: requestedTime, image: nsImage))
            case .failure:
                continue
            }
        }
        return results
    }

    func generateFrame(
        from asset: AVURLAsset,
        at time: CMTime,
        height: CGFloat
    ) async throws -> NSImage {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.maximumSize = CGSize(width: 0, height: height)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let (cgImage, _) = try await generator.image(at: time)
        return NSImage(
            cgImage: cgImage,
            size: NSSize(
                width: CGFloat(cgImage.width),
                height: CGFloat(cgImage.height)
            )
        )
    }
}
