import SwiftUI
import AppKit

struct AnimatedGIFView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.animates = true
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.canDrawSubviewsIntoLayer = true
        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        if nsView.image == nil || context.coordinator.currentURL != url {
            context.coordinator.currentURL = url
            if let image = NSImage(contentsOf: url) {
                nsView.image = image
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var currentURL: URL?
    }
}
