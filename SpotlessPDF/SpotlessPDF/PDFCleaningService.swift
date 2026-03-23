import Foundation

struct PDFCleaningService: Sendable {
    nonisolated func cleanPDF(at inputURL: URL, outputFolder: URL) throws -> URL {
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)

        let outputURL = uniqueOutputURL(for: inputURL, outputFolder: outputFolder)
        let engineURL = try resolveEngineURL()

        let process = Process()
        process.executableURL = engineURL
        process.arguments = [inputURL.path(percentEncoded: false), outputURL.path(percentEncoded: false)]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw PDFCleaningError.engineFailed(errorOutput?.isEmpty == false ? errorOutput! : "Rust engine exited with status \(process.terminationStatus).")
        }

        guard FileManager.default.fileExists(atPath: outputURL.path(percentEncoded: false)) else {
            throw PDFCleaningError.missingOutput
        }

        return outputURL
    }

    nonisolated private func uniqueOutputURL(for inputURL: URL, outputFolder: URL) -> URL {
        let sanitizedName = inputURL.deletingPathExtension().lastPathComponent
        let candidateURL = outputFolder
            .appendingPathComponent("\(sanitizedName)_cleaned", isDirectory: false)
            .appendingPathExtension("pdf")
        let fileManager = FileManager.default

        guard !fileManager.fileExists(atPath: candidateURL.path(percentEncoded: false)) else {
            var index = 2
            while true {
                let indexedURL = outputFolder
                    .appendingPathComponent("\(sanitizedName)_cleaned_\(index)", isDirectory: false)
                    .appendingPathExtension("pdf")

                if !fileManager.fileExists(atPath: indexedURL.path(percentEncoded: false)) {
                    return indexedURL
                }

                index += 1
            }
        }

        return candidateURL
    }

    nonisolated private func resolveEngineURL() throws -> URL {
        let bundle = Bundle.main
        if let bundledEngine = bundle.resourceURL?
            .appendingPathComponent("Rust", isDirectory: true)
            .appendingPathComponent("spotlesspdf_engine", isDirectory: false),
           FileManager.default.isExecutableFile(atPath: bundledEngine.path(percentEncoded: false)) {
            return bundledEngine
        }

        let projectEngine = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("SpotlessPDFRust", isDirectory: true)
            .appendingPathComponent("target", isDirectory: true)
            .appendingPathComponent("release", isDirectory: true)
            .appendingPathComponent("spotlesspdf_engine", isDirectory: false)

        if FileManager.default.isExecutableFile(atPath: projectEngine.path(percentEncoded: false)) {
            return projectEngine
        }

        let packagedProjectEngine = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("spotlesspdf_engine", isDirectory: false)

        if FileManager.default.isExecutableFile(atPath: packagedProjectEngine.path(percentEncoded: false)) {
            return packagedProjectEngine
        }

        throw PDFCleaningError.engineUnavailable
    }
}

enum PDFCleaningError: LocalizedError {
    case engineUnavailable
    case engineFailed(String)
    case missingOutput

    var errorDescription: String? {
        switch self {
        case .engineUnavailable:
            return "El motor Rust no está disponible todavía. Instala Rust y vuelve a compilar la app."
        case .engineFailed(let message):
            return "El motor Rust no pudo limpiar el PDF. \(message)"
        case .missingOutput:
            return "El motor Rust terminó, pero no generó el PDF de salida."
        }
    }
}
