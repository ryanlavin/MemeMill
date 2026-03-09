import Foundation
import AVFoundation
@testable import MemeMill

final class MockVideoLoader: VideoLoaderProtocol {
    var loadResult: Result<VideoSource, Error> = .success(
        VideoSource(
            id: UUID(),
            originalURL: URL(fileURLWithPath: "/test/video.mp4"),
            playableURL: URL(fileURLWithPath: "/test/video.mp4"),
            wasRemuxed: false,
            duration: CMTime(seconds: 60, preferredTimescale: 600),
            naturalSize: CGSize(width: 1920, height: 1080),
            frameRate: 24,
            fileSize: 10_000_000,
            fileName: "video.mp4"
        )
    )
    var loadCallCount = 0
    var cleanupCalled = false

    func load(from url: URL) async throws -> VideoSource {
        loadCallCount += 1
        return try loadResult.get()
    }

    func cleanupTemporaryFiles() {
        cleanupCalled = true
    }
}
