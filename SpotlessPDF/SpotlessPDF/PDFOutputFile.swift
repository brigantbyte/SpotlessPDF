import Foundation

/// Naming and publication are independent of the cleaning engine and UI language lookup.
nonisolated enum PDFOutputFile {
    static func destination(for input: URL, in folder: URL, preserveName: Bool, suffix: String) -> URL {
        if preserveName { return folder.appendingPathComponent(input.lastPathComponent) }
        let base = input.deletingPathExtension().lastPathComponent + suffix
        var candidate = folder.appendingPathComponent(base + ".pdf")
        var index = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = folder.appendingPathComponent("\(base)_\(index).pdf")
            index += 1
        }
        return candidate
    }

    static func save(_ staged: URL, to destination: URL, replacing: Bool) throws {
        let manager = FileManager.default
        if replacing && manager.fileExists(atPath: destination.path) {
            // Stage on the destination volume so replacement is atomic and the existing
            // PDF survives a failed engine run, cancellation, or failed staging copy.
            let replacementFolder = try manager.url(for: .itemReplacementDirectory,
                in: .userDomainMask, appropriateFor: destination, create: true)
            defer { try? manager.removeItem(at: replacementFolder) }
            let replacement = replacementFolder.appendingPathComponent(destination.lastPathComponent)
            try manager.copyItem(at: staged, to: replacement)
            _ = try manager.replaceItemAt(destination, withItemAt: replacement)
        } else {
            try manager.copyItem(at: staged, to: destination)
        }
    }
}
