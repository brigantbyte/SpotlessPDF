import AppKit
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isImporterPresented = false
    @State private var isDropTargeted = false
    @State private var outputURL: URL?
    @State private var errorMessage: String?
    @State private var metadata = ""
    @ObservedObject private var appState = AppState.shared
    @AppStorage(DownloadLocationStore.folderPathKey) private var storedDownloadFolderPath = ""
    private let cleaner = PDFCleaningService()
    private let brandColor = Color(red: 164.0 / 255, green: 64.0 / 255, blue: 69.0 / 255)

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                Spacer(minLength: 8)
                CleaningStatusIcon(isCleaning: appState.isCleaning, isComplete: outputURL != nil, accent: brandColor)
                    .frame(width: 52, height: 52)
                    .accessibilityHidden(true)
                if let url = appState.selectedPDFURL {
                    Text(url.lastPathComponent)
                        .font(.title3.weight(.semibold))
                        .lineLimit(2).truncationMode(.middle)
                        .help(url.path(percentEncoded: false))
                    if !metadata.isEmpty {
                        Text(metadata).font(.callout).foregroundStyle(.secondary)
                    }
                    VStack(spacing: 14) {
                        selectedActions
                    }
                    .frame(height: 72)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: appState.isCleaning)
                } else {
                    Text(L10n.dropPrompt).font(.title2.weight(.medium))
                    Text(L10n.appSubtitle)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button(L10n.loadPDF) { isImporterPresented = true }
                        .buttonStyle(.glassProminent)
                        .controlSize(.large)
                        .keyboardShortcut("o", modifiers: .command)
                }
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(isDropTargeted && !appState.isCleaning ? Color.accentColor : .clear,
                                  style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .padding(12).allowsHitTesting(false)
            }
            .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted, perform: handleDrop)

            Divider()
            HStack(spacing: 8) {
                Text(L10n.saveTo).foregroundStyle(.secondary)
                Label(FolderDisplayName.name(for: downloadFolderURL), systemImage: "folder")
                    .lineLimit(1).truncationMode(.middle)
                    .help(FolderDisplayName.path(for: downloadFolderURL))
                Spacer(minLength: 12)
                Button(L10n.changeLocation, action: chooseDownloadFolder)
                    .disabled(appState.isCleaning)
            }
            .font(.callout)
            .padding(.horizontal, 20).padding(.vertical, 14)
        }
        .frame(minWidth: 620, minHeight: 350)
        .background { frostedBackground.ignoresSafeArea() }
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url): appState.setSelectedPDF(from: url)
            case .failure(let error): errorMessage = error.localizedDescription
            }
        }
        .alert(L10n.appTitle, isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
        )) {} message: { Text(errorMessage ?? "") }
        .task(id: appState.selectedPDFURL) {
            outputURL = nil
            metadata = ""
            guard let url = appState.selectedPDFURL else { return }
            let value = await Task.detached(priority: .utility) {
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                let pages = PDFDocument(url: url)?.pageCount
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize
                return (pages, size)
            }.value
            guard !Task.isCancelled else { return }
            metadata = [value.0.map { L10n.pageCount($0) }, value.1.map {
                ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file)
            }].compactMap { $0 }.joined(separator: " · ")
        }
    }

    private var frostedBackground: some View {
        ZStack {
            colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : Color.white
            GeometryReader { geometry in
                LinearGradient(
                    colors: [
                        Color(red: 76.0 / 255, green: 126.0 / 255, blue: 209.0 / 255),
                        Color(red: 112.0 / 255, green: 106.0 / 255, blue: 181.0 / 255),
                        Color(red: 146.0 / 255, green: 83.0 / 255, blue: 130.0 / 255),
                        brandColor
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .mask {
                    Path { path in
                        path.move(to: CGPoint(x: geometry.size.width, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(.white)
                    .blur(radius: 22)
                }
            }
            .opacity(colorScheme == .dark ? 0.45 : 0.65)
            if !reduceTransparency {
                Rectangle().fill(.regularMaterial)
            } else {
                Color(nsColor: .windowBackgroundColor).opacity(0.65)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder private var selectedActions: some View {
        if appState.isCleaning {
            Text(L10n.cleaning)
                .font(.callout)
                .foregroundStyle(.secondary)
                .transition(.opacity)
        } else if let outputURL {
            Text(L10n.cleaningComplete).foregroundStyle(.secondary)
            GlassEffectContainer {
                HStack(spacing: 12) {
                    Button(L10n.showInFinder) {
                        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                    }
                    .buttonStyle(.glassProminent)
                    Button(L10n.loadAnother) { appState.clearSelectedPDF() }
                        .buttonStyle(.glass)
                }
                .controlSize(.large)
            }
        } else {
            Text(L10n.readyToClean).foregroundStyle(.secondary)
            GlassEffectContainer {
                HStack(spacing: 12) {
                    Button {
                        Task { await cleanSelectedPDF() }
                    } label: {
                        Label {
                            Text(L10n.clean)
                        } icon: {
                            Image(systemName: "paintbrush")
                                .scaleEffect(x: -1, y: -1)
                                .accessibilityHidden(true)
                        }
                    }
                        .buttonStyle(.glassProminent).tint(brandColor)
                        .keyboardShortcut(.defaultAction)
                    Button(L10n.removePDF) { appState.clearSelectedPDF() }
                        .buttonStyle(.glass)
                        .help(L10n.removeSelectedPDF)
                }
                .controlSize(.large)
            }
        }
    }

    private var downloadFolderURL: URL {
        DownloadLocationStore(folderPath: storedDownloadFolderPath).resolvedFolderURL
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard !appState.isCleaning,
              let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else { return false }
        provider.loadObject(ofClass: NSURL.self) { item, _ in
            let url = item as? URL
            Task { @MainActor in
                appState.setSelectedPDF(from: url)
            }
        }
        return true
    }

    private func chooseDownloadFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = downloadFolderURL
        guard let window = appState.mainWindow else { return }
        panel.beginSheetModal(for: window) { response in
            if response == .OK, let url = panel.url {
                storedDownloadFolderPath = url.path(percentEncoded: false)
            }
        }
    }

    @MainActor private func cleanSelectedPDF() async {
        guard !appState.isCleaning, let inputURL = appState.selectedPDFURL else { return }
        appState.isCleaning = true
        defer { appState.isCleaning = false }
        let folder = downloadFolderURL
        do {
            outputURL = try await Task.detached(priority: .userInitiated) {
                let accessed = inputURL.startAccessingSecurityScopedResource()
                defer { if accessed { inputURL.stopAccessingSecurityScopedResource() } }
                return try cleaner.cleanPDF(at: inputURL, outputFolder: folder)
            }.value
        } catch {
            errorMessage = L10n.cleaningFailedMessage(for: error)
        }
    }
}

private struct CleaningStatusIcon: View {
    let isCleaning: Bool
    let isComplete: Bool
    let accent: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var started = Date()
    @State private var closed = false
    @State private var green = false
    @State private var tick: CGFloat = 0
    @State private var endAngle = -90.0

    private var phase: Int { isComplete ? 2 : (isCleaning ? 1 : 0) }

    var body: some View {
        ZStack {
            if phase == 0 {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.secondary)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30, paused: phase != 1 || reduceMotion)) { context in
                    let angle = phase == 1 && !reduceMotion
                        ? context.date.timeIntervalSince(started) * 300 - 90 : endAngle
                    ZStack {
                        Circle().stroke(accent.opacity(0.12), lineWidth: 2.5)
                        Circle()
                            .trim(from: 0, to: closed ? 1 : 0.72)
                            .stroke(green ? Color.green : accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .rotationEffect(.degrees(angle))
                        CompletionTick()
                            .trim(from: 0, to: tick)
                            .stroke(.green, style: StrokeStyle(lineWidth: 2.7, lineCap: .round, lineJoin: .round))
                    }
                    .padding(4)
                }
                .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: phase == 0)
        .task(id: phase) {
            if phase != 2 {
                started = Date()
                closed = false
                green = false
                tick = 0
                endAngle = -90
                return
            }
            endAngle = reduceMotion ? -90 : Date().timeIntervalSince(started) * 300 - 90
            if reduceMotion {
                closed = true
                green = true
                tick = 1
                return
            }
            withAnimation(.easeOut(duration: 0.2)) { closed = true }
            do {
                try await Task.sleep(for: .milliseconds(200))
                withAnimation(.easeInOut(duration: 0.18)) { green = true }
                try await Task.sleep(for: .milliseconds(120))
                withAnimation(.easeOut(duration: 0.25)) { tick = 1 }
            } catch { /* A new PDF cancels the previous completion animation. */ }
        }
    }
}

private struct CompletionTick: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.width * 0.27, y: rect.height * 0.52))
            path.addLine(to: CGPoint(x: rect.width * 0.44, y: rect.height * 0.68))
            path.addLine(to: CGPoint(x: rect.width * 0.74, y: rect.height * 0.32))
        }
    }
}

#Preview { ContentView() }
