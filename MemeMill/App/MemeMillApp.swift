import SwiftUI

@main
struct MemeMillApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var preferences = UserPreferences()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
                .onOpenURL { url in
                    NotificationCenter.default.post(
                        name: .openVideoFile,
                        object: url
                    )
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Video...") {
                    NotificationCenter.default.post(
                        name: .openFilePicker,
                        object: nil
                    )
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(preferences)
        }
    }
}

extension Notification.Name {
    static let openVideoFile = Notification.Name("openVideoFile")
    static let openFilePicker = Notification.Name("openFilePicker")
}
