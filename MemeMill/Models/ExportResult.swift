import Foundation

enum ExportError: Error, LocalizedError, Equatable {
    case ffmpegNotFound
    case ffmpegFailed(exitCode: Int32, stderr: String)
    case invalidTimeRange
    case sourceFileNotFound
    case outputDirectoryNotWritable
    case captionRenderingFailed(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .ffmpegNotFound:
            return "FFmpeg was not found. Install it via: brew install ffmpeg"
        case .ffmpegFailed(let code, let stderr):
            return "FFmpeg exited with code \(code): \(String(stderr.prefix(200)))"
        case .invalidTimeRange:
            return "The selected time range is invalid."
        case .sourceFileNotFound:
            return "The source video file could not be found."
        case .outputDirectoryNotWritable:
            return "Cannot write to the output directory."
        case .captionRenderingFailed(let reason):
            return "Caption rendering failed: \(reason)"
        case .cancelled:
            return "Export was cancelled."
        }
    }
}
