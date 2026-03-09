import SwiftUI

struct SidebarView: View {
    @Binding var selectedItem: NavigationItem

    var body: some View {
        List(NavigationItem.allCases, selection: $selectedItem) { item in
            Label(item.rawValue, systemImage: item.icon)
                .tag(item)
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
    }
}
