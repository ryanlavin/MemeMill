import Foundation

struct GIFExportOptions: Equatable, Codable {
    var fps: Int
    var scale: ResolutionScale
    var quality: GIFQuality
    var speed: Double
    var loopCount: Int

    static let `default` = GIFExportOptions(
        fps: 15,
        scale: .half,
        quality: .high,
        speed: 1.0,
        loopCount: 0
    )
}

enum ResolutionScale: String, CaseIterable, Codable, Identifiable {
    case quarter = "25%"
    case third = "33%"
    case half = "50%"
    case twoThirds = "67%"
    case full = "100%"

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .quarter: return 0.25
        case .third: return 1.0 / 3.0
        case .half: return 0.5
        case .twoThirds: return 2.0 / 3.0
        case .full: return 1.0
        }
    }
}

enum GIFQuality: String, CaseIterable, Codable, Identifiable {
    case low
    case medium
    case high
    case maximum

    var id: String { rawValue }

    var statsMode: String {
        switch self {
        case .low, .medium: return "full"
        case .high, .maximum: return "diff"
        }
    }

    var ditherAlgorithm: String {
        switch self {
        case .low: return "bayer"
        case .medium: return "sierra2_4a"
        case .high: return "floyd_steinberg"
        case .maximum: return "sierra3"
        }
    }
}
