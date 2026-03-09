import AppKit
import Foundation
@testable import MemeMill

final class MockCaptionRenderer: CaptionRendererProtocol {
    var renderCallCount = 0
    var renderResult: Result<Void, Error> = .success(())
    var lastLayout: CaptionLayout?
    var previewCallCount = 0

    func renderCaptions(
        on sourceGIF: URL,
        layout: CaptionLayout,
        outputURL: URL,
        progressHandler: ((Double) -> Void)?
    ) throws {
        renderCallCount += 1
        lastLayout = layout
        progressHandler?(0.5)
        progressHandler?(1.0)
        try renderResult.get()

        // Create a dummy output file
        let gifHeader: [UInt8] = [
            0x47, 0x49, 0x46, 0x38, 0x39, 0x61,
            0x01, 0x00, 0x01, 0x00,
            0x00, 0x00, 0x00,
            0x3B
        ]
        try Data(gifHeader).write(to: outputURL)
    }

    func previewCaption(on frame: NSImage, layout: CaptionLayout) -> NSImage {
        previewCallCount += 1
        return frame // Return unchanged for mock
    }
}
