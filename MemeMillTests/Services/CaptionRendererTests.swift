import XCTest
import ImageIO
@testable import MemeMill

final class CaptionRendererTests: XCTestCase {

    var tempDir: URL!
    var renderer: CaptionRenderer!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemeMill_caption_renderer_test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        renderer = CaptionRenderer()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Render Captions

    func testRenderCaptionsWithEmptyLayoutCopiesFile() throws {
        let sourceURL = try createTestGIF(named: "source.gif")
        let outputURL = tempDir.appendingPathComponent("output.gif")

        try renderer.renderCaptions(
            on: sourceURL,
            layout: .empty,
            outputURL: outputURL,
            progressHandler: nil
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }

    func testRenderCaptionsProducesOutputWithCorrectFrameCount() throws {
        let sourceURL = try createTestGIF(named: "source.gif", frameCount: 3)
        let outputURL = tempDir.appendingPathComponent("captioned.gif")

        let layout = CaptionLayout(
            topText: "TOP",
            bottomText: "BOTTOM",
            topStyle: .memeDefault,
            bottomStyle: .memeDefault
        )

        try renderer.renderCaptions(
            on: sourceURL,
            layout: layout,
            outputURL: outputURL,
            progressHandler: nil
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        // Verify frame count
        guard let source = CGImageSourceCreateWithURL(outputURL as CFURL, nil) else {
            XCTFail("Could not read output GIF")
            return
        }
        XCTAssertEqual(CGImageSourceGetCount(source), 3)
    }

    func testRenderCaptionsProgressHandlerCalled() throws {
        let sourceURL = try createTestGIF(named: "progress_test.gif", frameCount: 5)
        let outputURL = tempDir.appendingPathComponent("progress_output.gif")

        var progressValues: [Double] = []
        let layout = CaptionLayout(
            topText: "TEST",
            bottomText: "",
            topStyle: .memeDefault,
            bottomStyle: .memeDefault
        )

        try renderer.renderCaptions(
            on: sourceURL,
            layout: layout,
            outputURL: outputURL,
            progressHandler: { progress in
                progressValues.append(progress)
            }
        )

        XCTAssertFalse(progressValues.isEmpty)
        XCTAssertEqual(progressValues.last, 1.0)
    }

    func testRenderCaptionsWithInvalidSourceThrows() {
        let invalidURL = tempDir.appendingPathComponent("nonexistent.gif")
        let outputURL = tempDir.appendingPathComponent("output.gif")

        let layout = CaptionLayout(
            topText: "TEST",
            bottomText: "",
            topStyle: .memeDefault,
            bottomStyle: .memeDefault
        )

        XCTAssertThrowsError(try renderer.renderCaptions(
            on: invalidURL,
            layout: layout,
            outputURL: outputURL,
            progressHandler: nil
        ))
    }

    // MARK: - Preview Caption

    func testPreviewCaptionReturnsSameSizeImage() {
        let frame = createTestNSImage(width: 320, height: 240)
        let layout = CaptionLayout(
            topText: "HELLO",
            bottomText: "WORLD",
            topStyle: .memeDefault,
            bottomStyle: .memeDefault
        )

        let result = renderer.previewCaption(on: frame, layout: layout)
        XCTAssertEqual(result.size.width, frame.size.width, accuracy: 1)
        XCTAssertEqual(result.size.height, frame.size.height, accuracy: 1)
    }

    // MARK: - Helpers

    private func createTestGIF(named name: String, frameCount: Int = 1) throws -> URL {
        let url = tempDir.appendingPathComponent(name)

        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            "com.compuserve.gif" as CFString,
            frameCount,
            nil
        ) else {
            throw NSError(domain: "Test", code: 1)
        }

        // Set GIF properties (loop count)
        let gifProps: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0
            ]
        ]
        CGImageDestinationSetProperties(destination, gifProps as CFDictionary)

        for _ in 0..<frameCount {
            let image = createTestCGImage(width: 100, height: 100)
            let frameProps: [String: Any] = [
                kCGImagePropertyGIFDictionary as String: [
                    kCGImagePropertyGIFDelayTime as String: 0.1
                ]
            ]
            CGImageDestinationAddImage(destination, image, frameProps as CFDictionary)
        }

        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "Test", code: 2)
        }

        return url
    }

    private func createTestCGImage(width: Int, height: Int) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }

    private func createTestNSImage(width: Int, height: Int) -> NSImage {
        let cgImage = createTestCGImage(width: width, height: height)
        return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    }
}
