import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case editor = "Editor"
    case gallery = "Gallery"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .editor: return "film"
        case .gallery: return "photo.on.rectangle.angled"
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: NavigationItem = .editor
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedItem: $selectedItem)
        } detail: {
            switch selectedItem {
            case .editor:
                VideoEditorView()
                    .environmentObject(preferences)
            case .gallery:
                GalleryView()
                    .environmentObject(preferences)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}
