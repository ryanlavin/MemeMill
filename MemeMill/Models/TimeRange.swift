import AVFoundation

struct TimeRange: Equatable, Codable {
    var start: Double
    var end: Double

    var duration: Double { max(0, end - start) }

    var cmTimeRange: CMTimeRange {
        CMTimeRange(
            start: CMTime(seconds: start, preferredTimescale: 600),
            duration: CMTime(seconds: duration, preferredTimescale: 600)
        )
    }

    func clamped(to videoDuration: Double) -> TimeRange {
        let clampedStart = max(0, min(start, videoDuration))
        let clampedEnd = max(0, min(end, videoDuration))
        return TimeRange(start: clampedStart, end: clampedEnd)
    }

    var isValid: Bool { start < end && duration > 0 }

    static let maxGIFDuration: Double = 30.0

    var isWithinGIFLimit: Bool { duration <= Self.maxGIFDuration }
}
