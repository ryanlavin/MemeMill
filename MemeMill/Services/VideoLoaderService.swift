import AVFoundation
import Foundation

final class VideoLoaderService: VideoLoaderProtocol {
    private let ffmpeg: FFmpegServiceProtocol
    private var temporaryFiles: [URL] = []

    private static let avFoundationSupportedExtensions: Set<String> = [
        "mp4", "mov", "m4v"
    ]

    private static let needsRemux: Set<String> = [
        "mkv", "webm", "avi"
    ]

    init(ffmpeg: FFmpegServiceProtocol) {
        self.ffmpeg = ffmpeg
    }

    func load(from url: URL) async throws -> VideoSource {
        let ext = url.pathExtension.lowercased()
        let playableURL: URL
        let wasRemuxed: Bool

        if Self.needsRemux.contains(ext) {
            playableURL = try await remuxToMP4(source: url)
            wasRemuxed = true
        } else {
            playableURL = url
            wasRemuxed = false
        }

        let asset = AVURLAsset(url: playableURL)
        let duration = try await asset.load(.duration)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = tracks.first else {
            throw ExportError.sourceFileNotFound
        }
        let size = try await videoTrack.load(.naturalSize)
        let frameRate = try await videoTrack.load(.nominalFrameRate)
        let fileSize = (try? FileManager.default
            .attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0

        return VideoSource(
            id: UUID(),
            originalURL: url,
            playableURL: playableURL,
            wasRemuxed: wasRemuxed,
            duration: duration,
            naturalSize: size,
            frameRate: frameRate,
            fileSize: fileSize,
            fileName: url.lastPathComponent
        )
    }

    private func remuxToMP4(source: URL) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemeMill", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let outputURL = tempDir.appendingPathComponent("\(UUID().uuidString).mp4")
        temporaryFiles.append(outputURL)

        // Attempt 1: stream copy (fastest)
        do {
            _ = try await ffmpeg.run(arguments: [
                "-i", source.path,
                "-c", "copy",
                "-movflags", "+faststart",
                "-y",
                outputURL.path
            ], progressHandler: nil)
            return outputURL
        } catch {
            // Attempt 2: re-encode if stream copy fails
            _ = try await ffmpeg.run(arguments: [
                "-i", source.path,
                "-c:v", "libx264",
                "-preset", "ultrafast",
                "-crf", "18",
                "-c:a", "aac",
                "-movflags", "+faststart",
                "-y",
                outputURL.path
            ], progressHandler: nil)
            return outputURL
        }
    }

    func cleanupTemporaryFiles() {
        for url in temporaryFiles {
            try? FileManager.default.removeItem(at: url)
        }
        temporaryFiles.removeAll()
    }
}
