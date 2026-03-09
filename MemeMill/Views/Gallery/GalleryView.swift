import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var preferences: UserPreferences
    @StateObject private var viewModel: GalleryViewModel
    @State private var showCaptionEditor = false
    @State private var captionTemplate: GIFTemplate?

    init() {
        let prefs = UserPreferences()
        let store = TemplateStore(outputDirectory: prefs.outputDirectory)
        _viewModel = StateObject(wrappedValue: GalleryViewModel(templateStore: store))
    }

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            galleryToolbar

            if viewModel.filteredTemplates.isEmpty {
                emptyState
            } else {
                HSplitView {
                    // Grid of thumbnails
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.filteredTemplates) { template in
                                GIFThumbnailView(
                                    template: template,
                                    isSelected: viewModel.selectedTemplate?.id == template.id
                                )
                                .onTapGesture {
                                    viewModel.selectedTemplate = template
                                }
                                .contextMenu {
                                    Button("Add Caption") {
                                        captionTemplate = template
                                        showCaptionEditor = true
                                    }
                                    Button("Reveal in Finder") {
                                        viewModel.revealInFinder(template)
                                    }
                                    Button("Copy") {
                                        viewModel.copyToClipboard(template)
                                    }
                                    Divider()
                                    Button("Delete", role: .destructive) {
                                        viewModel.deleteTemplate(template)
                                    }
                                }
                            }
                        }
                        .padding()
                    }

                    // Detail panel
                    if let selected = viewModel.selectedTemplate {
                        ScrollView {
                            GIFDetailView(
                                template: selected,
                                onCaption: {
                                    captionTemplate = selected
                                    showCaptionEditor = true
                                },
                                onReveal: {
                                    viewModel.revealInFinder(selected)
                                },
                                onCopy: {
                                    viewModel.copyToClipboard(selected)
                                },
                                onDelete: {
                                    viewModel.deleteTemplate(selected)
                                }
                            )
                        }
                        .frame(minWidth: 300, maxWidth: 400)
                    }
                }
            }
        }
        .task {
            await viewModel.refresh()
        }
        .sheet(isPresented: $showCaptionEditor) {
            if let template = captionTemplate {
                CaptionEditorView(
                    sourceTemplate: template,
                    templateStore: viewModel.templateStore
                )
            }
        }
    }

    // MARK: - Subviews

    private var galleryToolbar: some View {
        HStack {
            Text("Template Gallery")
                .font(.headline)

            Spacer()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search...", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }

            // Sort
            Picker("Sort", selection: $viewModel.sortOrder) {
                ForEach(GalleryViewModel.SortOrder.allCases) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .frame(width: 150)

            // Refresh
            Button(action: {
                Task { await viewModel.refresh() }
            }) {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(viewModel.isRefreshing)

            // Open directory
            Button(action: {
                NSWorkspace.shared.open(preferences.outputDirectory)
            }) {
                Image(systemName: "folder")
            }
            .help("Open output directory")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No templates yet")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Export a GIF from the Editor tab to get started")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
