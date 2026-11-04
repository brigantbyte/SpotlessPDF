import Foundation

// Run this executable inside a temporary .app with its own test engine.
@main struct PDFCleaningServiceChecks {
    static func main() throws {
        let manager = FileManager.default
        let resources = Bundle.main.resourceURL!.appendingPathComponent("Rust")
        try manager.createDirectory(at: resources, withIntermediateDirectories: true)
        let engine = resources.appendingPathComponent("spotlesspdf_engine")
        let folder = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? manager.removeItem(at: folder) }
        let input = folder.appendingPathComponent("input.pdf")
        let output = folder.appendingPathComponent("output.pdf")
        let source = Data("test payload".utf8)
        try source.write(to: input)
        func install(_ script: String) throws {
            try Data(("#!/bin/sh\n" + script).utf8).write(to: engine)
            try manager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: engine.path)
        }
        let cleaner = PDFCleaningService()
        try install("cp \"$1\" \"$2\"\n")
        _ = try cleaner.cleanPDF(at: input, outputURL: output)
        let result = try Data(contentsOf: output)
        precondition(result == source)
        try manager.removeItem(at: output)
        try install("exit 0\n")
        do {
            _ = try cleaner.cleanPDF(at: input, outputURL: output)
            preconditionFailure("Missing output was accepted")
        } catch PDFCleaningError.missingOutput { }
        try install("/usr/bin/yes diagnostic | /usr/bin/head -c 262144 >&2\nexit 7\n")
        do {
            _ = try cleaner.cleanPDF(at: input, outputURL: output)
            preconditionFailure("Engine failure was accepted")
        } catch PDFCleaningError.engineFailed(let message) {
            precondition(message.utf8.count > 200000)
        }
        try manager.removeItem(at: engine)
        do {
            _ = try cleaner.cleanPDF(at: input, outputURL: output)
            preconditionFailure("Missing engine was accepted")
        } catch PDFCleaningError.engineUnavailable { }
        print("Passed: successful output, missing output, large diagnostics without blocking, and missing engine.")
    }
}
