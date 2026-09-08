import Foundation

// Compile with FolderDisplayName.swift. This loads real translations from the
// built application without changing the user's language or destination.
enum AppLocalization {
    static let bundle = Bundle(path: CommandLine.arguments[1])!
    static var language = "es"
    static func localized(_ key: String) -> String {
        let localized = Bundle(path: bundle.path(forResource: language, ofType: "lproj")!)!
        return localized.localizedString(forKey: key, value: nil, table: "Localizable")
    }
}

@main struct FolderDisplayNameChecks {
    static func main() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        precondition(FolderDisplayName.name(for: documents) == "Documentos")
        precondition(FolderDisplayName.name(for: URL(fileURLWithPath: documents.path)) == "Documentos")
        precondition(FolderDisplayName.path(for: documents.appendingPathComponent("Facturas")) == "Documentos / Facturas")
        precondition(FolderDisplayName.name(for: home.appendingPathComponent("Personal/Documents")) == "Documents")
        precondition(FolderDisplayName.path(for: home.appendingPathComponent("Documents-old")) == "Inicio / Documents-old")
        precondition(FolderDisplayName.name(for: URL(fileURLWithPath: "/Users/Shared")) == "Compartido")
        precondition(FolderDisplayName.name(for: URL(fileURLWithPath: "/tmp/Documents")) == "Documents")
        AppLocalization.language = "de"
        precondition(FolderDisplayName.name(for: documents) == "Dokumente")
        AppLocalization.language = "fr"
        precondition(FolderDisplayName.name(for: FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]) == "Bureau")
        AppLocalization.language = "ar"
        precondition(FolderDisplayName.name(for: documents) == "المستندات")
        print("Folder names and paths: passed, including language overrides and custom-name preservation.")
    }
}
