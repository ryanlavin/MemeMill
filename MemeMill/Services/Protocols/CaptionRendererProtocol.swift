import AppKit
import Foundation

protocol CaptionRendererProtocol {
    func renderCaptions(
        on sourceGIF: URL,
        layout: CaptionLayout,
        outputURL: URL,
        progressHandler: ((Double) -> Void)?
    ) throws

    func previewCaption(
        on frame: NSImage,
        layout: CaptionLayout
    ) -> NSImage
}
