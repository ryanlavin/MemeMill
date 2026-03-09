import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var preferences: UserPreferences

    var body: some View {
        VStack {
            Text("Template Gallery")
                .font(.title2)
            Text("Exported GIF templates will appear here")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
