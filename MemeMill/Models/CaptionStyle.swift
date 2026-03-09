import AppKit

struct CaptionStyle: Equatable, Codable {
    var fontName: String
    var fontSize: CGFloat
    var textColorHex: String
    var strokeColorHex: String
    var strokeWidth: CGFloat
    var alignment: CaptionAlignment

    static let memeDefault = CaptionStyle(
        fontName: "Impact",
        fontSize: 48,
        textColorHex: "#FFFFFF",
        strokeColorHex: "#000000",
        strokeWidth: 3.0,
        alignment: .center
    )
}

enum CaptionAlignment: String, CaseIterable, Codable, Identifiable {
    case leading
    case center
    case trailing

    var id: String { rawValue }
}

extension NSColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6 else { return nil }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }

    var hexString: String {
        guard let rgb = usingColorSpace(.sRGB) else { return "#000000" }
        let r = Int(rgb.redComponent * 255)
        let g = Int(rgb.greenComponent * 255)
        let b = Int(rgb.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
