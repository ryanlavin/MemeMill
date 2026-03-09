import AppKit
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

final class CaptionRenderer: CaptionRendererProtocol {

    func renderCaptions(
        on sourceGIF: URL,
        layout: CaptionLayout,
        outputURL: URL,
        progressHandler: ((Double) -> Void)?
    ) throws {
        guard layout.hasContent else {
            try FileManager.default.copyItem(at: sourceGIF, to: outputURL)
            return
        }

        guard let source = CGImageSourceCreateWithURL(sourceGIF as CFURL, nil) else {
            throw ExportError.captionRenderingFailed("Cannot read source GIF")
        }

        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 0 else {
            throw ExportError.captionRenderingFailed("GIF has no frames")
        }

        // Read GIF-level properties
        let gifProperties = CGImageSourceCopyProperties(source, nil) as? [String: Any]
        let gifDict = gifProperties?[kCGImagePropertyGIFDictionary as String] as? [String: Any]
        let loopCount = gifDict?[kCGImagePropertyGIFLoopCount as String] as? Int ?? 0

        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            UTType.gif.identifier as CFString,
            frameCount,
            nil
        ) else {
            throw ExportError.captionRenderingFailed("Cannot create output GIF")
        }

        // Set GIF-level properties
        let destGIFProps: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: loopCount
            ]
        ]
        CGImageDestinationSetProperties(destination, destGIFProps as CFDictionary)

        for i in 0..<frameCount {
            progressHandler?(Double(i) / Double(frameCount))

            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else {
                continue
            }

            let frameProps = CGImageSourceCopyPropertiesAtIndex(source, i, nil)
            let captionedImage = drawCaptions(on: cgImage, layout: layout)
            CGImageDestinationAddImage(destination, captionedImage, frameProps)
        }

        guard CGImageDestinationFinalize(destination) else {
            throw ExportError.captionRenderingFailed("Failed to finalize GIF")
        }
        progressHandler?(1.0)
    }

    func previewCaption(on frame: NSImage, layout: CaptionLayout) -> NSImage {
        guard let cgImage = frame.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return frame
        }
        let captioned = drawCaptions(on: cgImage, layout: layout)
        return NSImage(cgImage: captioned, size: frame.size)
    }

    // MARK: - Core Text Drawing

    private func drawCaptions(on image: CGImage, layout: CaptionLayout) -> CGImage {
        let width = image.width
        let height = image.height

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return image
        }

        // Draw original frame
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Draw top text
        if !layout.topText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            drawText(
                layout.topText,
                style: layout.topStyle,
                in: context,
                imageWidth: width,
                imageHeight: height,
                position: .top
            )
        }

        // Draw bottom text
        if !layout.bottomText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            drawText(
                layout.bottomText,
                style: layout.bottomStyle,
                in: context,
                imageWidth: width,
                imageHeight: height,
                position: .bottom
            )
        }

        return context.makeImage() ?? image
    }

    private enum TextPosition { case top, bottom }

    private func drawText(
        _ text: String,
        style: CaptionStyle,
        in context: CGContext,
        imageWidth: Int,
        imageHeight: Int,
        position: TextPosition
    ) {
        let scaledFontSize = style.fontSize * CGFloat(imageHeight) / 480.0

        let font = CTFontCreateWithName(style.fontName as CFString, scaledFontSize, nil)

        let textColor = NSColor(hex: style.textColorHex) ?? .white
        let strokeColor = NSColor(hex: style.strokeColorHex) ?? .black

        // Draw stroke (outline) pass
        let strokeAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: strokeColor,
            .strokeColor: strokeColor,
            .strokeWidth: style.strokeWidth * 2,
        ]

        // Draw fill pass
        let fillAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
        ]

        let upperText = text.uppercased()

        // Measure text
        let attrString = NSAttributedString(string: upperText, attributes: fillAttributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        let maxWidth = CGFloat(imageWidth) * 0.9
        let textSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRangeMake(0, attrString.length),
            nil,
            CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            nil
        )

        let margin = CGFloat(imageWidth) * 0.05
        let x = (CGFloat(imageWidth) - textSize.width) / 2
        let y: CGFloat

        switch position {
        case .top:
            y = CGFloat(imageHeight) - textSize.height - margin
        case .bottom:
            y = margin
        }

        let textRect = CGRect(x: x, y: y, width: textSize.width + 10, height: textSize.height + 5)

        context.saveGState()

        // Draw stroke text
        let strokeAttrString = NSAttributedString(string: upperText, attributes: strokeAttributes)
        let strokeFramesetter = CTFramesetterCreateWithAttributedString(strokeAttrString)
        let strokePath = CGPath(rect: textRect, transform: nil)
        let strokeFrame = CTFramesetterCreateFrame(strokeFramesetter, CFRangeMake(0, 0), strokePath, nil)
        CTFrameDraw(strokeFrame, context)

        // Draw fill text on top
        let fillPath = CGPath(rect: textRect, transform: nil)
        let fillFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), fillPath, nil)
        CTFrameDraw(fillFrame, context)

        context.restoreGState()
    }
}
