import Foundation

enum FFmpegProgressParser {
    static func parse(_ line: String) -> FFmpegProgress? {
        let timeSeconds = parseTime(from: line)
        let speed = parseSpeed(from: line)
        let frames = parseFrames(from: line)

        guard timeSeconds != nil || speed != nil || frames != nil else {
            return nil
        }

        return FFmpegProgress(
            timeSeconds: timeSeconds,
            speed: speed,
            framesProcessed: frames
        )
    }

    private static func parseTime(from line: String) -> Double? {
        guard let range = line.range(of: #"time=(\d{2}):(\d{2}):(\d{2})\.(\d{2})"#, options: .regularExpression) else {
            return nil
        }
        let match = String(line[range])
        let components = match.replacingOccurrences(of: "time=", with: "")
            .components(separatedBy: CharacterSet(charactersIn: ":."))
        guard components.count >= 4,
              let hours = Double(components[0]),
              let minutes = Double(components[1]),
              let seconds = Double(components[2]),
              let centiseconds = Double(components[3]) else {
            return nil
        }
        return hours * 3600 + minutes * 60 + seconds + centiseconds / 100.0
    }

    private static func parseSpeed(from line: String) -> Double? {
        guard let range = line.range(of: #"speed=\s*([\d.]+)x"#, options: .regularExpression) else {
            return nil
        }
        let match = String(line[range])
        let value = match.replacingOccurrences(of: "speed=", with: "")
            .replacingOccurrences(of: "x", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(value)
    }

    private static func parseFrames(from line: String) -> Int? {
        guard let range = line.range(of: #"frame=\s*(\d+)"#, options: .regularExpression) else {
            return nil
        }
        let match = String(line[range])
        let value = match.replacingOccurrences(of: "frame=", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Int(value)
    }
}
