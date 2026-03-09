import AppKit
import AVFoundation

protocol ThumbnailGeneratorProtocol {
    func generateThumbnails(
        from asset: AVURLAsset,
        count: Int,
        height: CGFloat
    ) async throws -> [(time: CMTime, image: NSImage)]

    func generateFrame(
        from asset: AVURLAsset,
        at time: CMTime,
        height: CGFloat
    ) async throws -> NSImage
}
