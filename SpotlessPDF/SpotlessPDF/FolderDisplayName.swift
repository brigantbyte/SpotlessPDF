import Foundation

/// Translates only actual system folders, never similarly named user folders.
/// Display strings are kept separate from URLs used to read and write files.
enum FolderDisplayName {
    private static var knownFolders: [(url: URL, key: String)] {
        let manager = FileManager.default
        let directories: [(FileManager.SearchPathDirectory, String)] = [
            (.downloadsDirectory, "downloads"), (.desktopDirectory, "desktop"),
            (.documentDirectory, "documents"), (.picturesDirectory, "pictures"),
            (.musicDirectory, "music"), (.moviesDirectory, "movies"),
            (.sharedPublicDirectory, "public")
        ]
        var folders = directories.compactMap { directory, key in
            manager.urls(for: directory, in: .userDomainMask).first.map { ($0, key) }
        }
        folders.append((manager.homeDirectoryForCurrentUser, "home"))
        folders.append((manager.homeDirectoryForCurrentUser.appendingPathComponent("Applications"), "applications"))
        if let applications = manager.urls(for: .applicationDirectory, in: .localDomainMask).first {
            folders.append((applications, "applications"))
        }
        if let users = manager.urls(for: .userDirectory, in: .localDomainMask).first {
            folders.append((users.appendingPathComponent("Shared"), "shared"))
        }
        return folders.map { ($0.0.standardizedFileURL.resolvingSymlinksInPath(), "folder." + $0.1) }
    }

    static func name(for url: URL) -> String {
        let normalized = url.standardizedFileURL.resolvingSymlinksInPath()
        if let folder = knownFolders.first(where: { $0.url == normalized }) {
            return AppLocalization.localized(folder.key)
        }
        return url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
    }

    static func path(for url: URL) -> String {
        let components = url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
        let folders = knownFolders.sorted { $0.url.pathComponents.count > $1.url.pathComponents.count }
        for folder in folders {
            let prefix = folder.url.pathComponents
            guard components.starts(with: prefix) else { continue }
            return ([AppLocalization.localized(folder.key)] + components.dropFirst(prefix.count)).joined(separator: " / ")
        }
        return url.path(percentEncoded: false)
    }
}
