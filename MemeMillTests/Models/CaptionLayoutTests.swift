import XCTest
@testable import MemeMill

final class CaptionLayoutTests: XCTestCase {

    // MARK: - CaptionStyle Defaults

    func testMemeDefaultStyle() {
        let style = CaptionStyle.memeDefault
        XCTAssertEqual(style.fontName, "Impact")
        XCTAssertEqual(style.fontSize, 48)
        XCTAssertEqual(style.textColorHex, "#FFFFFF")
        XCTAssertEqual(style.strokeColorHex, "#000000")
        XCTAssertEqual(style.strokeWidth, 3.0)
        XCTAssertEqual(style.alignment, .center)
    }

    // MARK: - CaptionLayout hasContent

    func testHasContentFalseWhenEmpty() {
        let layout = CaptionLayout.empty
        XCTAssertFalse(layout.hasContent)
    }

    func testHasContentFalseWhenWhitespaceOnly() {
        let layout = CaptionLayout(
            topText: "   ",
            bottomText: "\n\t",
            topStyle: .memeDefault,
            bottomStyle: .memeDefault
        )
        XCTAssertFalse(layout.hasContent)
    }

    func testHasContentTrueWithTopText() {
        let layout = CaptionLayout(
            topText: "Hello",
            bottomText: "",
            topStyle: .memeDefault,
            bottomStyle: .memeDefault
        )
        XCTAssertTrue(layout.hasContent)
    }

    func testHasContentTrueWithBottomText() {
        let layout = CaptionLayout(
            topText: "",
            bottomText: "World",
            topStyle: .memeDefault,
            bottomStyle: .memeDefault
        )
        XCTAssertTrue(layout.hasContent)
    }

    func testHasContentTrueWithBothTexts() {
        let layout = CaptionLayout(
            topText: "Top",
            bottomText: "Bottom",
            topStyle: .memeDefault,
            bottomStyle: .memeDefault
        )
        XCTAssertTrue(layout.hasContent)
    }

    // MARK: - CaptionLayout Codable

    func testCaptionLayoutCodableRoundTrip() throws {
        let original = CaptionLayout(
            topText: "Top Text",
            bottomText: "Bottom Text",
            topStyle: CaptionStyle(
                fontName: "Helvetica-Bold",
                fontSize: 36,
                textColorHex: "#FF0000",
                strokeColorHex: "#00FF00",
                strokeWidth: 2.0,
                alignment: .leading
            ),
            bottomStyle: .memeDefault
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CaptionLayout.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - CaptionStyle Codable

    func testCaptionStyleCodableRoundTrip() throws {
        let original = CaptionStyle.memeDefault
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CaptionStyle.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - CaptionAlignment

    func testCaptionAlignmentAllCases() {
        XCTAssertEqual(CaptionAlignment.allCases.count, 3)
    }

    // MARK: - NSColor hex

    func testNSColorFromHexWhite() {
        let color = NSColor(hex: "#FFFFFF")
        XCTAssertNotNil(color)
        XCTAssertEqual(color?.redComponent ?? 0, 1.0, accuracy: 0.01)
        XCTAssertEqual(color?.greenComponent ?? 0, 1.0, accuracy: 0.01)
        XCTAssertEqual(color?.blueComponent ?? 0, 1.0, accuracy: 0.01)
    }

    func testNSColorFromHexBlack() {
        let color = NSColor(hex: "#000000")
        XCTAssertNotNil(color)
        XCTAssertEqual(color?.redComponent ?? 1, 0.0, accuracy: 0.01)
    }

    func testNSColorFromHexRed() {
        let color = NSColor(hex: "#FF0000")
        XCTAssertNotNil(color)
        XCTAssertEqual(color?.redComponent ?? 0, 1.0, accuracy: 0.01)
        XCTAssertEqual(color?.greenComponent ?? 1, 0.0, accuracy: 0.01)
        XCTAssertEqual(color?.blueComponent ?? 1, 0.0, accuracy: 0.01)
    }

    func testNSColorFromHexWithoutHash() {
        let color = NSColor(hex: "00FF00")
        XCTAssertNotNil(color)
        XCTAssertEqual(color?.greenComponent ?? 0, 1.0, accuracy: 0.01)
    }

    func testNSColorFromHexInvalidReturnsNil() {
        XCTAssertNil(NSColor(hex: "invalid"))
        XCTAssertNil(NSColor(hex: "#FFF"))
    }

    func testNSColorHexStringRoundTrip() {
        let original = NSColor(hex: "#FF8800")!
        let hex = original.hexString
        let reconstructed = NSColor(hex: hex)
        XCTAssertNotNil(reconstructed)
        XCTAssertEqual(original.redComponent, reconstructed!.redComponent, accuracy: 0.02)
        XCTAssertEqual(original.greenComponent, reconstructed!.greenComponent, accuracy: 0.02)
        XCTAssertEqual(original.blueComponent, reconstructed!.blueComponent, accuracy: 0.02)
    }
}
