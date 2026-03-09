import Foundation

final class GIFExportService: GIFExporterProtocol {
    private let ffmpeg: FFmpegServiceProtocol

    init(ffmpeg: FFmpegServiceProtocol) {
        self.ffmpeg = ffmpeg
    }

    func exportGIF(
        from source: VideoSource,
        timeRange: TimeRange,
        options: GIFExportOptions,
        outputDirectory: URL,
        progressHandler: (@Sendable (Double) -> Void)?
    ) async throws -> GIFTemplate {
        guard timeRange.isValid else { throw ExportError.invalidTimeRange }

        // Ensure output directory exists
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemeMill/\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let palettePath = tempDir.appendingPathComponent("palette.png").path
        let timestamp = Self.dateFormatter.string(from: Date())
        let safeName = source.fileName
            .components(separatedBy: ".").dropLast().joined(separator: ".")
            .replacingOccurrences(of: " ", with: "_")
        let outputFileName = "\(safeName)_\(timestamp).gif"
        let outputURL = outputDirectory.appendingPathComponent(outputFileName)

        // Calculate scaled width (must be divisible by 2 for FFmpeg)
        let scaledWidth = Int(source.naturalSize.width * options.scale.multiplier)
        let evenWidth = scaledWidth % 2 == 0 ? scaledWidth : scaledWidth - 1

        let filterBase = buildFilterBase(
            fps: options.fps,
            width: evenWidth,
            speed: options.speed
        )

        // Pass 1: Generate palette
        progressHandler?(0.1)
        let pass1Args = buildPass1Arguments(
            inputPath: source.originalURL.path,
            timeRange: timeRange,
            filterBase: filterBase,
            statsMode: options.quality.statsMode,
            palettePath: palettePath
        )
        _ = try await ffmpeg.run(arguments: pass1Args, progressHandler: { progress in
            if let t = progress.timeSeconds {
                let fraction = min(t / timeRange.duration, 1.0)
                progressHandler?(0.1 + fraction * 0.4)
            }
        })

        // Pass 2: Create GIF with palette
        progressHandler?(0.5)
        let pass2Args = buildPass2Arguments(
            inputPath: source.originalURL.path,
            timeRange: timeRange,
            filterBase: filterBase,
            ditherAlgorithm: options.quality.ditherAlgorithm,
            palettePath: palettePath,
            outputPath: outputURL.path,
            loopCount: options.loopCount
        )
        _ = try await ffmpeg.run(arguments: pass2Args, progressHandler: { progress in
            if let t = progress.timeSeconds {
                let fraction = min(t / timeRange.duration, 1.0)
                progressHandler?(0.5 + fraction * 0.45)
            }
        })

        progressHandler?(1.0)

        let attrs = try FileManager.default.attributesOfItem(atPath: outputURL.path)
        let fileSize = (attrs[.size] as? Int64) ?? 0

        let scaledHeight = Int(source.naturalSize.height * options.scale.multiplier)
        let evenHeight = scaledHeight % 2 == 0 ? scaledHeight : scaledHeight - 1

        let template = GIFTemplate(
            id: UUID(),
            fileName: outputFileName,
            fileURL: outputURL,
            createdAt: Date(),
            sourceVideoName: source.fileName,
            timeRange: timeRange,
            options: options,
            fileSizeBytes: fileSize,
            dimensions: CGSize(width: evenWidth, height: evenHeight)
        )

        return template
    }

    func cancel() async {
        await ffmpeg.cancel()
    }

    // MARK: - FFmpeg Argument Builders

    func buildFilterBase(fps: Int, width: Int, speed: Double) -> String {
        let setpts = speed != 1.0 ? "setpts=\(1.0 / speed)*PTS," : ""
        return "\(setpts)fps=\(fps),scale=\(width):-1:flags=lanczos"
    }

    func buildPass1Arguments(
        inputPath: String,
        timeRange: TimeRange,
        filterBase: String,
        statsMode: String,
        palettePath: String
    ) -> [String] {
        [
            "-ss", String(timeRange.start),
            "-t", String(timeRange.duration),
            "-i", inputPath,
            "-vf", "\(filterBase),palettegen=stats_mode=\(statsMode)",
            "-y",
            palettePath
        ]
    }

    func buildPass2Arguments(
        inputPath: String,
        timeRange: TimeRange,
        filterBase: String,
        ditherAlgorithm: String,
        palettePath: String,
        outputPath: String,
        loopCount: Int
    ) -> [String] {
        [
            "-ss", String(timeRange.start),
            "-t", String(timeRange.duration),
            "-i", inputPath,
            "-i", palettePath,
            "-lavfi", "\(filterBase) [x]; [x][1:v] paletteuse=dither=\(ditherAlgorithm)",
            "-loop", String(loopCount),
            "-y",
            outputPath
        ]
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return df
    }()
}
