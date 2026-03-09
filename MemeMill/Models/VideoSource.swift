import Foundation
import AVFoundation

struct VideoSource: Identifiable, Equatable {
    let id: UUID
    let originalURL: URL
    let playableURL: URL
    let wasRemuxed: Bool
    let duration: CMTime
    let naturalSize: CGSize
    let frameRate: Float
    let fileSize: Int64
    let fileName: String

    var durationSeconds: Double {
        CMTimeGetSeconds(duration)
    }

    static func == (lhs: VideoSource, rhs: VideoSource) -> Bool {
        lhs.id == rhs.id
    }
}
