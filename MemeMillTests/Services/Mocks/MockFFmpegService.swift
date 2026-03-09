import Foundation
@testable import MemeMill

final class MockFFmpegService: FFmpegServiceProtocol, @unchecked Sendable {
    var locateResult: URL? = URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
    var runResults: [Result<Data, Error>] = [.success(Data())]
    var runCallCount = 0
    var runArguments: [[String]] = []
    var cancelCalled = false

    func locateFFmpeg() -> URL? { locateResult }

    func run(
        arguments: [String],
        progressHandler: (@Sendable (FFmpegProgress) -> Void)?
    ) async throws -> Data {
        let index = min(runCallCount, runResults.count - 1)
        runCallCount += 1
        runArguments.append(arguments)
        return try runResults[index].get()
    }

    func cancel() async { cancelCalled = true }
}
