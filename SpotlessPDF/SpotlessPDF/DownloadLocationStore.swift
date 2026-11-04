import Foundation

struct DownloadLocationStore {
    static let folderPathKey = "downloadFolderPath"

    let folderPath: String

    var resolvedFolderURL: URL {
        guard !folderPath.isEmpty else {
            return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads", isDirectory: true)
        }

        return URL(fileURLWithPath: folderPath, isDirectory: true)
    }
}
