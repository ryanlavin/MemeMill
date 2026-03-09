import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var preferences: UserPreferences
    @State private var showDirectoryPicker = false

    var body: some View {
        Form {
            Section("Output Directory") {
                HStack {
                    Text(preferences.outputDirectory.path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Choose...") {
                        chooseDirectory()
                    }
                }
            }

            Section("Default Export Options") {
                Picker("FPS", selection: $preferences.lastUsedExportOptions.fps) {
                    ForEach([5, 10, 15, 20, 24, 30], id: \.self) { fps in
                        Text("\(fps) fps").tag(fps)
                    }
                }

                Picker("Scale", selection: $preferences.lastUsedExportOptions.scale) {
                    ForEach(ResolutionScale.allCases) { scale in
                        Text(scale.rawValue).tag(scale)
                    }
                }

                Picker("Quality", selection: $preferences.lastUsedExportOptions.quality) {
                    ForEach(GIFQuality.allCases) { quality in
                        Text(quality.rawValue.capitalized).tag(quality)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 300)
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            preferences.outputDirectory = url
        }
    }
}
