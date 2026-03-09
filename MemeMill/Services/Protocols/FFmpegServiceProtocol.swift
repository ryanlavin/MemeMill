import Foundation

struct FFmpegProgress: Sendable {
    let timeSeconds: Double?
    let speed: Double?
    let framesProcessed: Int?
}

protocol FFmpegServiceProtocol: Sendable {
    func locateFFmpeg() -> URL?
    func run(
        arguments: [String],
        progressHandler: (@Sendable (FFmpegProgress) -> Void)?
    ) async throws -> Data
    func cancel() async
}
