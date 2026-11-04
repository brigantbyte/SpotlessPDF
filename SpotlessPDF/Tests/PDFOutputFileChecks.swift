import AppKit
import Foundation

@main struct PDFOutputFileChecks {
    static func main() throws {
        let manager = FileManager.default
        let folder = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? manager.removeItem(at: folder) }
        let bundle = Bundle(path: CommandLine.arguments[1])!
        var checkedLanguages = 0
        for language in bundle.localizations where language != "Base" {
            guard let path = bundle.path(forResource: language, ofType: "lproj"),
                  let localized = Bundle(path: path) else { continue }
            func text(_ key: String) -> String {
                let result = localized.localizedString(forKey: key, value: nil, table: "Localizable")
                precondition(result != key && !result.isEmpty, "Missing \(language): \(key)")
                return result
            }
            let suffix = text("save.cleaned_suffix")
            precondition(suffix.hasPrefix("_") && !suffix.contains("/"))
            let label = text("save.preserve_name")
            _ = text("save.replace_title")
            _ = text("save.replace")
            _ = text("save.cancel")
            let input = folder.appendingPathComponent("archivo.pdf")
            let destination = PDFOutputFile.destination(for: input, in: folder, preserveName: false, suffix: suffix)
            precondition(destination.lastPathComponent == "archivo\(suffix).pdf")
            if language == "es" { precondition(destination.lastPathComponent == "archivo_limpio.pdf") }
            if language == "en" {
                let file = folder.appendingPathComponent("file.pdf")
                precondition(PDFOutputFile.destination(for: file, in: folder, preserveName: false, suffix: suffix).lastPathComponent == "file_cleaned.pdf")
            }
            // The fixed controls leave useful folder space in the existing 620pt window.
            let font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular))
            let fixedWidth = [text("workspace.save_to"), label]
                .reduce(CGFloat.zero) { $0 + ($1 as NSString).size(withAttributes: [.font: font]).width }
            precondition(fixedWidth + 200 + 40 + 24 + 16 + 22 <= 620, "Footer too wide: \(language)")
            checkedLanguages += 1
        }
        precondition(checkedLanguages == 33)
        let input = folder.appendingPathComponent("Résumé.PDF")
        let sameName = PDFOutputFile.destination(for: input, in: folder, preserveName: true, suffix: "_limpio")
        precondition(sameName.lastPathComponent == "Résumé.PDF")
        let original = Data("original".utf8)
        let cleaned = Data("cleaned".utf8)
        let staged = folder.appendingPathComponent("staged.pdf")
        try original.write(to: sameName)
        try cleaned.write(to: staged)
        do {
            try PDFOutputFile.save(staged, to: sameName, replacing: false)
            preconditionFailure("An existing file was silently overwritten")
        } catch CocoaError.fileWriteFileExists { }
        let afterRefusal = try Data(contentsOf: sameName)
        precondition(afterRefusal == original)
        // Cancel does not call save; both the original and staged result still exist.
        precondition(manager.fileExists(atPath: staged.path))
        try PDFOutputFile.save(staged, to: sameName, replacing: true)
        let afterReplacement = try Data(contentsOf: sameName)
        precondition(afterReplacement == cleaned)
        let first = PDFOutputFile.destination(for: input, in: folder, preserveName: false, suffix: "_limpio")
        try PDFOutputFile.save(staged, to: first, replacing: false)
        let second = PDFOutputFile.destination(for: input, in: folder, preserveName: false, suffix: "_limpio")
        precondition(second.lastPathComponent == "Résumé_limpio_2.pdf")
        precondition(PDFOutputFile.destination(for: input, in: folder, preserveName: false, suffix: "_cleaned").lastPathComponent == "Résumé_cleaned.pdf")
        let absent = folder.appendingPathComponent("new.pdf")
        try PDFOutputFile.save(staged, to: absent, replacing: false)
        let newContents = try Data(contentsOf: absent)
        precondition(newContents == cleaned)
        print("Passed: 33 localizations, footer text widths, exact name, numbered collisions, refusal to overwrite, explicit replacement, and language-dependent suffixes.")
    }
}
