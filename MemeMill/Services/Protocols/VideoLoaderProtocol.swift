import Foundation

protocol VideoLoaderProtocol {
    func load(from url: URL) async throws -> VideoSource
    func cleanupTemporaryFiles()
}
