import Foundation
import Combine

final class UserPreferences: ObservableObject {
    @Published var outputDirectory: URL {
        didSet {
            UserDefaults.standard.set(outputDirectory.path, forKey: Keys.outputDirectory)
        }
    }
    @Published var lastUsedExportOptions: GIFExportOptions {
        didSet {
            if let data = try? JSONEncoder().encode(lastUsedExportOptions) {
                UserDefaults.standard.set(data, forKey: Keys.lastExportOptions)
            }
        }
    }

    private enum Keys {
        static let outputDirectory = "outputDirectory"
        static let lastExportOptions = "lastExportOptions"
    }

    init() {
        let defaultDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop/MemeTemplates")

        if let savedPath = UserDefaults.standard.string(forKey: Keys.outputDirectory) {
            self.outputDirectory = URL(fileURLWithPath: savedPath)
        } else {
            self.outputDirectory = defaultDir
        }

        if let data = UserDefaults.standard.data(forKey: Keys.lastExportOptions),
           let options = try? JSONDecoder().decode(GIFExportOptions.self, from: data) {
            self.lastUsedExportOptions = options
        } else {
            self.lastUsedExportOptions = .default
        }
    }
}
