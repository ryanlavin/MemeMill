# MemeMill

A native macOS app for extracting GIF meme templates from videos and captioning them.

## Features

- **Open any video format**: MP4, MOV, MKV, AVI, WebM via file picker, drag-and-drop, or "Open With"
- **Visual timeline scrubber**: Frame thumbnails for quick navigation with draggable start/end markers
- **GIF export options**: FPS (5-30), resolution scale (25-100%), quality (4 dither algorithms), speed (0.25-4x), loop control
- **Two-pass GIF pipeline**: Uses FFmpeg palettegen + paletteuse for dramatically better color quality
- **Template gallery**: Browse, search, sort, and manage exported GIF templates
- **Meme captioning**: Add top/bottom text with customizable font, size, color, and stroke (Impact font with outline by default)
- **Core Graphics rendering**: Captioning uses Core Text for frame-by-frame text overlay - no additional dependencies needed

## Requirements

- macOS 14.0 (Sonoma) or later
- FFmpeg installed via Homebrew: `brew install ffmpeg`
- Xcode 16+ (for building)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Getting Started

```bash
# Clone the repo
git clone https://github.com/ryanlavin/MemeMill.git
cd MemeMill

# Install dependencies
brew install ffmpeg xcodegen

# Generate Xcode project and build
make generate
make build

# Run tests (145 tests)
make test
```

Or open `MemeMill.xcodeproj` in Xcode after running `make generate`.

## Architecture

- **SwiftUI** for all UI (macOS 14+)
- **AVFoundation** for video playback and frame extraction
- **FFmpeg** (Homebrew) for GIF creation and MKV/WebM/AVI remux
- **Core Graphics + Core Text** for GIF captioning
- **MVVM** with protocol-driven services for testability
- **XcodeGen** for project generation from `project.yml`

### Project Structure

```
MemeMill/
├── App/         # App entry point, AppDelegate, Info.plist
├── Models/      # VideoSource, TimeRange, GIFExportOptions, GIFTemplate, Caption*
├── Services/    # FFmpeg, VideoLoader, GIFExport, CaptionRenderer, TemplateStore
├── ViewModels/  # VideoEditor, Timeline, Export, Gallery, CaptionEditor
└── Views/       # Editor, Gallery, Caption, Shared components
```

### GIF Pipeline

```
Video → FFmpeg palettegen → optimal 256-color palette
     → FFmpeg paletteuse → high-quality dithered GIF
```

For MKV/WebM/AVI: automatic remux to MP4 via FFmpeg (stream copy, falls back to re-encode).

## Usage

1. **Open a video**: Cmd+O or drag a video file onto the editor
2. **Navigate**: Use the timeline scrubber, play/pause (Space), or step frames (arrow keys)
3. **Set range**: Drag the green (start) and red (end) markers on the timeline
4. **Configure**: Adjust FPS, scale, quality, and speed in the export panel
5. **Export**: Click "Export GIF" - output goes to your configured directory
6. **Caption**: Switch to Gallery tab, select a template, click "Add Caption"
7. **Style**: Customize font, size, colors, and stroke width for meme text

## Testing

145 tests across all layers:
- **Model tests**: TimeRange, GIFExportOptions, CaptionLayout, NSColor hex
- **Service tests**: FFmpegLocator, FFmpegProgressParser, FFmpegService, VideoLoaderService, GIFExportService, CaptionRenderer, TemplateStore
- **ViewModel tests**: VideoEditorVM, TimelineVM, ExportVM, GalleryVM, CaptionEditorVM
- **Integration tests**: Full GIF export pipeline, caption pipeline, metadata round-trip

## License

MIT
