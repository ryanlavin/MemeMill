import Foundation

protocol TemplateStoreProtocol: ObservableObject {
    var templates: [GIFTemplate] { get }
    var outputDirectory: URL { get set }
    func refresh() async
    func delete(_ template: GIFTemplate) throws
    func saveMetadata(for template: GIFTemplate) throws
}
