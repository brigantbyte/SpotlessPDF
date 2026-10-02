import Foundation

struct PDFCleaningService: Sendable {
    nonisolated func cleanPDF(at inputURL: URL, outputURL: URL) throws -> URL {
        try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let engineURL = try resolveEngineURL()

        let process = Process()
        process.executableURL = engineURL
        process.arguments = [inputURL.path(percentEncoded: false), outputURL.path(percentEncoded: false)]

        // A file avoids blocking the engine when diagnostics exceed a pipe's capacity.
        let errorURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data().write(to: errorURL, options: .withoutOverwriting)
        defer { try? FileManager.default.removeItem(at: errorURL) }
        let errorHandle = try FileHandle(forWritingTo: errorURL)
        defer { try? errorHandle.close() }
        process.standardOutput = FileHandle.nullDevice
        process.standardError = errorHandle

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = try Data(contentsOf: errorURL)
            let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let message = errorOutput.flatMap { $0.isEmpty ? nil : $0 }
                ?? "Rust engine exited with status \(process.terminationStatus)."
            throw PDFCleaningError.engineFailed(message)
        }

        guard FileManager.default.fileExists(atPath: outputURL.path(percentEncoded: false)) else {
            throw PDFCleaningError.missingOutput
        }

        return outputURL
    }

    nonisolated private func resolveEngineURL() throws -> URL {
        let bundle = Bundle.main
        if let bundledEngine = bundle.resourceURL?
            .appendingPathComponent("Rust", isDirectory: true)
            .appendingPathComponent("spotlesspdf_engine", isDirectory: false),
           FileManager.default.isExecutableFile(atPath: bundledEngine.path(percentEncoded: false)) {
            return bundledEngine
        }

        throw PDFCleaningError.engineUnavailable
    }
}

enum PDFCleaningError: Error {
    case engineUnavailable
    case engineFailed(String)
    case missingOutput
}
