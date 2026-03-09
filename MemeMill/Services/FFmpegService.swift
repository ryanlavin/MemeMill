import Foundation

actor FFmpegService: FFmpegServiceProtocol {
    private var currentProcess: Process?
    private let ffmpegURL: URL?

    init(ffmpegURL: URL? = nil) {
        self.ffmpegURL = ffmpegURL ?? FFmpegLocator.locate()
    }

    nonisolated func locateFFmpeg() -> URL? {
        ffmpegURL
    }

    func run(
        arguments: [String],
        progressHandler: (@Sendable (FFmpegProgress) -> Void)? = nil
    ) async throws -> Data {
        guard let ffmpeg = ffmpegURL else {
            throw ExportError.ffmpegNotFound
        }

        let process = Process()
        process.executableURL = ffmpeg
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        currentProcess = process

        if let handler = progressHandler {
            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty,
                      let line = String(data: data, encoding: .utf8) else { return }
                if let progress = FFmpegProgressParser.parse(line) {
                    handler(progress)
                }
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { [weak self] proc in
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                let stdout = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                if proc.terminationStatus == 0 {
                    continuation.resume(returning: stdout)
                } else {
                    let stderr = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    let msg = String(data: stderr, encoding: .utf8) ?? ""
                    continuation.resume(throwing: ExportError.ffmpegFailed(
                        exitCode: proc.terminationStatus, stderr: msg
                    ))
                }
                Task { [weak self] in
                    await self?.clearCurrentProcess()
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: ExportError.ffmpegFailed(
                    exitCode: -1, stderr: error.localizedDescription
                ))
            }
        }
    }

    func cancel() {
        currentProcess?.terminate()
        currentProcess = nil
    }

    private func clearCurrentProcess() {
        currentProcess = nil
    }
}
