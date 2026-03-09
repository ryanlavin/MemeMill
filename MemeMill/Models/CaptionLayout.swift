import Foundation

struct CaptionLayout: Equatable, Codable {
    var topText: String
    var bottomText: String
    var topStyle: CaptionStyle
    var bottomStyle: CaptionStyle

    static let empty = CaptionLayout(
        topText: "",
        bottomText: "",
        topStyle: .memeDefault,
        bottomStyle: .memeDefault
    )

    var hasContent: Bool {
        !topText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !bottomText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
