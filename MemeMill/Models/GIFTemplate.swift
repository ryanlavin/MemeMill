import Foundation

struct GIFTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    let fileName: String
    let fileURL: URL
    let createdAt: Date
    let sourceVideoName: String
    let timeRange: TimeRange
    let options: GIFExportOptions
    let fileSizeBytes: Int64
    let dimensions: CGSize

    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
    }

    var durationFormatted: String {
        let duration = timeRange.duration
        if duration < 1.0 {
            return String(format: "%.1fs", duration)
        }
        return String(format: "%.1fs", duration)
    }
}

extension CGSize: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(width: width, height: height)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
}
