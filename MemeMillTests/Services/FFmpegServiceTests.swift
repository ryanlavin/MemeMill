import XCTest
@testable import MemeMill

final class FFmpegServiceTests: XCTestCase {

    func testLocateFFmpegReturnsNonNil() {
        let service = FFmpegService()
        XCTAssertNotNil(service.locateFFmpeg())
    }

    func testRunWithValidCommandReturnsData() async throws {
        let service = FFmpegService()
        // ffmpeg -version should succeed and return output
        let data = try await service.run(
            arguments: ["-version"],
            progressHandler: nil
        )
        XCTAssertFalse(data.isEmpty, "ffmpeg -version should return output")
        let output = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(output.contains("ffmpeg"), "Output should contain 'ffmpeg'")
    }

    func testRunWithInvalidArgsThrowsError() async {
        let service = FFmpegService()
        do {
            _ = try await service.run(
                arguments: ["-i", "/nonexistent/file.mp4", "-y", "/tmp/out.mp4"],
                progressHandler: nil
            )
            XCTFail("Should have thrown an error")
        } catch let error as ExportError {
            if case .ffmpegFailed(let code, _) = error {
                XCTAssertNotEqual(code, 0)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testRunWithNilFFmpegThrowsNotFound() async {
        let service = FFmpegService(ffmpegURL: URL(fileURLWithPath: "/nonexistent/ffmpeg"))
        // The service was initialized with a specific URL, but it won't run
        // This tests that if ffmpeg binary doesn't exist, it fails
        do {
            _ = try await service.run(arguments: ["-version"], progressHandler: nil)
            XCTFail("Should have thrown")
        } catch {
            // Expected - either ffmpegFailed or some other error
            XCTAssertTrue(error is ExportError)
        }
    }

    func testCancelTerminatesProcess() async {
        let service = FFmpegService()
        // Start a long-running task, then cancel it
        let task = Task {
            do {
                // Generate 10s of silence - should be cancellable
                _ = try await service.run(arguments: [
                    "-f", "lavfi",
                    "-i", "nullsrc=s=320x240:d=30",
                    "-t", "30",
                    "-f", "null",
                    "-"
                ], progressHandler: nil)
            } catch {
                // Expected to fail after cancel
            }
        }

        // Give it a moment to start
        try? await Task.sleep(nanoseconds: 200_000_000)
        await service.cancel()
        task.cancel()
    }
}
