import SwiftUI
import AVFoundation

struct TimelineView: View {
    @ObservedObject var timelineVM: TimelineViewModel
    @Binding var currentTime: Double
    @Binding var timeRange: TimeRange
    let duration: Double
    let onSeek: (Double) -> Void

    @State private var isDraggingPlayhead = false
    @State private var isDraggingStart = false
    @State private var isDraggingEnd = false

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height: CGFloat = 60

            ZStack(alignment: .leading) {
                // Thumbnail strip background
                thumbnailStrip(width: width, height: height)

                // Selected range highlight
                selectedRangeOverlay(width: width, height: height)

                // Start marker handle
                markerHandle(
                    position: positionForTime(timeRange.start, width: width),
                    height: height,
                    color: .green,
                    isDragging: $isDraggingStart
                ) { newPosition in
                    let time = timeForPosition(newPosition, width: width)
                    var newRange = timeRange
                    newRange.start = time
                    if newRange.isValid {
                        timeRange = newRange
                    }
                }

                // End marker handle
                markerHandle(
                    position: positionForTime(timeRange.end, width: width),
                    height: height,
                    color: .red,
                    isDragging: $isDraggingEnd
                ) { newPosition in
                    let time = timeForPosition(newPosition, width: width)
                    var newRange = timeRange
                    newRange.end = time
                    if newRange.isValid {
                        timeRange = newRange
                    }
                }

                // Playhead
                playheadIndicator(
                    position: positionForTime(currentTime, width: width),
                    height: height
                )
            }
            .frame(height: height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDraggingStart && !isDraggingEnd {
                            let time = timeForPosition(value.location.x, width: width)
                            onSeek(time)
                        }
                    }
            )
        }
        .frame(height: 60)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func thumbnailStrip(width: CGFloat, height: CGFloat) -> some View {
        if timelineVM.thumbnails.isEmpty {
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: width, height: height)
        } else {
            HStack(spacing: 0) {
                ForEach(Array(timelineVM.thumbnails.enumerated()), id: \.offset) { _, thumbnail in
                    Image(nsImage: thumbnail.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: width / CGFloat(timelineVM.thumbnails.count),
                            height: height
                        )
                        .clipped()
                }
            }
        }
    }

    private func selectedRangeOverlay(width: CGFloat, height: CGFloat) -> some View {
        let startX = positionForTime(timeRange.start, width: width)
        let endX = positionForTime(timeRange.end, width: width)
        let rangeWidth = max(0, endX - startX)

        return Rectangle()
            .fill(Color.accentColor.opacity(0.2))
            .border(Color.accentColor, width: 1)
            .frame(width: rangeWidth, height: height)
            .offset(x: startX)
    }

    private func markerHandle(
        position: CGFloat,
        height: CGFloat,
        color: Color,
        isDragging: Binding<Bool>,
        onDrag: @escaping (CGFloat) -> Void
    ) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: 4, height: height + 10)
            .offset(x: position - 2)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging.wrappedValue = true
                        onDrag(value.location.x)
                    }
                    .onEnded { _ in
                        isDragging.wrappedValue = false
                    }
            )
            .cursor(.resizeLeftRight)
    }

    private func playheadIndicator(position: CGFloat, height: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 2, height: height + 16)
            .shadow(color: .black.opacity(0.5), radius: 1)
            .offset(x: position - 1)
    }

    // MARK: - Position Helpers

    private func timeForPosition(_ x: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0 }
        return max(0, min(Double(x / width) * duration, duration))
    }

    private func positionForTime(_ time: Double, width: CGFloat) -> CGFloat {
        guard duration > 0 else { return 0 }
        return CGFloat(time / duration) * width
    }
}

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
