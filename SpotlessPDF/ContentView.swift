import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    private enum CleaningStatus {
        case idle
        case cleaning
        case success
        case error
    }

    @Environment(\.colorScheme) private var colorScheme
    @State private var isImporterPresented = false
    @State private var isCleaning = false
    @State private var cleaningStatus: CleaningStatus = .idle
    @State private var isDropTargeted = false
    @ObservedObject private var appState = AppState.shared

    @AppStorage(DownloadLocationStore.folderPathKey)
    private var storedDownloadFolderPath = ""

    private let cleaner = PDFCleaningService()
    private let cardCornerRadius: CGFloat = 16

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                header
                selectedFileCard
                actions
                cleaningStatusView
            }
            .padding(32)
            .frame(maxWidth: 720)
        }
        .frame(minWidth: 640, minHeight: 420)
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted, perform: handleDrop)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.appTitle)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(primaryTextColor)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.15), radius: colorScheme == .dark ? 8 : 6, x: 0, y: 2)

            Text(L10n.appSubtitle)
                .font(.title3)
                .foregroundStyle(secondaryTextColor)
                .shadow(color: backgroundTextShadowColor, radius: 4, x: 0, y: 1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var selectedFileCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Label(L10n.selectedPDF, systemImage: "doc.richtext")
                    .font(.headline)
                    .foregroundStyle(cardPrimaryTextColor)

                Spacer(minLength: 12)

                Group {
                    if appState.selectedPDFURL != nil {
                        Button {
                            resetLoadedPDF()
                        } label: {
                            Image(systemName: "paintbrush.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.78))
                                .rotationEffect(.degrees(130))
                                .frame(width: 32, height: 32)
                                .glassEffect(.regular.tint(.red), in: .circle)
                        }
                        .buttonStyle(.plain)
                        .help(L10n.removeSelectedPDF)
                    } else {
                        Color.clear
                            .frame(width: 32, height: 32)
                    }
                }
                .frame(width: 32, height: 32)
            }

            Text(appState.selectedPDFURL?.lastPathComponent ?? L10n.noPDFLoaded)
                .font(.title3.weight(.semibold))
                .foregroundStyle(appState.selectedPDFURL == nil ? cardSecondaryTextColor : cardPrimaryTextColor)

            Text(L10n.currentDestination(downloadFolderURL.path(percentEncoded: false)))
                .font(.footnote)
                .foregroundStyle(cardAuxiliaryTextColor)
                .textSelection(.enabled)

            Button {
                chooseDownloadFolder()
            } label: {
                Text(L10n.changeLocation)
            }
            .buttonStyle(.glass)
            .controlSize(.small)
            .tint(changeLocationTintColor)
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                        .stroke(isDropTargeted ? changeLocationTintColor.opacity(0.85) : cardStrokeColor, lineWidth: isDropTargeted ? 2 : 1)
                )
                .shadow(color: cardShadowColor, radius: colorScheme == .dark ? 14 : 18, y: colorScheme == .dark ? 6 : 8)
        )
    }

    private var actions: some View {
        HStack(spacing: 16) {
            Button {
                isImporterPresented = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.down")
                    Text(L10n.loadPDF)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(changeLocationTintColor)
            .foregroundStyle(.white)

            Button {
                Task {
                    await cleanSelectedPDF()
                }
            } label: {
                HStack(spacing: 10) {
                    Label(L10n.clean, systemImage: "sparkles.rectangle.stack")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(appState.selectedPDFURL == nil || isCleaning ? nil : .orange)
            .foregroundStyle(cleanButtonTextColor)
            .disabled(appState.selectedPDFURL == nil || isCleaning)
        }
    }

    private var cleaningStatusView: some View {
        HStack(spacing: 12) {
            Group {
                switch cleaningStatus {
                case .cleaning:
                    ProgressView()
                        .progressViewStyle(.linear)
                        .controlSize(.small)
                case .success:
                    ProgressView(value: 1)
                        .tint(.orange)
                        .progressViewStyle(.linear)
                        .controlSize(.small)
                case .error:
                    ProgressView(value: 1)
                        .tint(.red)
                        .progressViewStyle(.linear)
                        .controlSize(.small)
                case .idle:
                    EmptyView()
                }
            }

            Image(systemName: statusIconName)
                .symbolRenderingMode(cleaningStatus == .success ? .palette : .monochrome)
                .foregroundStyle(statusPrimaryColor, statusSecondaryColor)
                .opacity(cleaningStatus == .cleaning ? 0 : 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 20)
        .opacity(cleaningStatus == .idle ? 0 : 1)
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 15 / 255, green: 17 / 255, blue: 21 / 255),
                Color(red: 36 / 255, green: 96 / 255, blue: 168 / 255),
                Color(red: 168 / 255, green: 90 / 255, blue: 31 / 255)
            ]
        }

        return [
            Color(red: 0 / 255, green: 136 / 255, blue: 255 / 255),
            Color(red: 255 / 255, green: 141 / 255, blue: 40 / 255)
        ]
    }

    private var cardFillColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.20)
            : Color.white.opacity(0.56)
    }

    private var cardStrokeColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.10)
            : Color.white.opacity(0.68)
    }

    private var cardShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.30) : Color.black.opacity(0.08)
    }

    private var primaryTextColor: Color {
        .white
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.90) : Color.white.opacity(0.96)
    }

    private var cardPrimaryTextColor: Color {
        colorScheme == .dark
            ? Color(red: 234 / 255, green: 234 / 255, blue: 234 / 255)
            : Color(red: 32 / 255, green: 32 / 255, blue: 32 / 255)
    }

    private var cardSecondaryTextColor: Color {
        colorScheme == .dark
            ? Color(red: 176 / 255, green: 176 / 255, blue: 176 / 255)
            : Color(red: 72 / 255, green: 72 / 255, blue: 72 / 255)
    }

    private var cardAuxiliaryTextColor: Color {
        colorScheme == .dark
            ? Color(red: 136 / 255, green: 136 / 255, blue: 136 / 255)
            : Color(red: 98 / 255, green: 98 / 255, blue: 98 / 255)
    }

    private var backgroundTextShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.30) : Color.black.opacity(0.12)
    }

    private var changeLocationTintColor: Color {
        colorScheme == .dark
            ? Color(red: 64 / 255, green: 156 / 255, blue: 255 / 255)
            : Color(red: 0 / 255, green: 136 / 255, blue: 255 / 255)
    }

    private var cleanButtonTextColor: Color {
        colorScheme == .dark
            ? Color(red: 204 / 255, green: 204 / 255, blue: 204 / 255)
            : Color(red: 68 / 255, green: 68 / 255, blue: 68 / 255)
    }

    private var downloadFolderURL: URL {
        DownloadLocationStore(folderPath: storedDownloadFolderPath).resolvedFolderURL
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            setSelectedPDF(from: urls.first)
        case .failure:
            break
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let resolvedURL: URL?

            if let url = item as? URL {
                resolvedURL = url
            } else if let data = item as? Data {
                resolvedURL = URL(dataRepresentation: data, relativeTo: nil)
            } else if let string = item as? String {
                resolvedURL = URL(string: string)
            } else {
                resolvedURL = nil
            }

            guard let resolvedURL else {
                return
            }

            Task { @MainActor in
                setSelectedPDF(from: resolvedURL)
            }
        }

        return true
    }

    private func setSelectedPDF(from url: URL?) {
        appState.setSelectedPDF(from: url)
    }

    private func chooseDownloadFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = downloadFolderURL

        if panel.runModal() == .OK, let url = panel.url {
            storedDownloadFolderPath = url.path(percentEncoded: false)
        }
    }

    private func resetLoadedPDF() {
        appState.clearSelectedPDF()
    }

    @MainActor
    private func cleanSelectedPDF() async {
        guard let selectedPDFURL = appState.selectedPDFURL else {
            return
        }

        isCleaning = true
        cleaningStatus = .cleaning
        let outputFolderURL = downloadFolderURL

        do {
            _ = try await Task.detached(priority: .userInitiated) {
                try cleaner.cleanPDF(at: selectedPDFURL, outputFolder: outputFolderURL)
            }.value

            cleaningStatus = .success
        } catch {
            cleaningStatus = .error
            showErrorAlert(message: L10n.cleaningFailedMessage(for: error))
        }

        isCleaning = false
        scheduleStatusReset()
    }

    @MainActor
    private var statusIconName: String {
        switch cleaningStatus {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        default:
            return "circle.fill"
        }
    }

    private var statusPrimaryColor: Color {
        switch cleaningStatus {
        case .success:
            return .white
        case .error:
            return .orange
        default:
            return .clear
        }
    }

    private var statusSecondaryColor: Color {
        cleaningStatus == .success ? .green : .clear
    }

    @MainActor
    private func scheduleStatusReset() {
        Task {
            try? await Task.sleep(for: .seconds(2))
            if !isCleaning {
                cleaningStatus = .idle
            }
        }
    }

    @MainActor
    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.appTitle
        alert.informativeText = message
        alert.runModal()
    }
}

#Preview {
    ContentView()
}
