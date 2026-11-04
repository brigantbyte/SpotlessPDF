import AppKit
import SwiftUI

/// A native pop-up keeps the folder selected while treating “Other…” as an action.
struct DestinationFolderPicker: NSViewRepresentable {
    let folderURL: URL
    let folderName: String
    let folderPath: String
    let otherTitle: String
    let accessibilityLabel: String
    let isEnabled: Bool
    let chooseFolder: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(chooseFolder: chooseFolder)
    }

    func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        button.controlSize = .regular
        button.font = .systemFont(ofSize: NSFont.systemFontSize(for: .regular))
        button.addItem(withTitle: folderName)
        button.addItem(withTitle: otherTitle)
        button.target = context.coordinator
        button.action = #selector(Coordinator.selectItem(_:))
        button.cell?.lineBreakMode = .byTruncatingMiddle
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return button
    }

    func updateNSView(_ button: NSPopUpButton, context: Context) {
        context.coordinator.chooseFolder = chooseFolder
        button.item(at: 0)?.title = folderName
        // Copy the Finder icon before resizing; NSWorkspace may share its cached image.
        let icon = NSWorkspace.shared.icon(forFile: folderURL.path).copy() as! NSImage
        icon.size = NSSize(width: 16, height: 16)
        button.item(at: 0)?.image = icon
        button.item(at: 1)?.title = otherTitle
        button.selectItem(at: 0)
        button.isEnabled = isEnabled
        button.toolTip = folderPath
        button.setAccessibilityLabel(accessibilityLabel)
        button.setAccessibilityValue(folderName)
    }

    final class Coordinator: NSObject {
        var chooseFolder: () -> Void

        init(chooseFolder: @escaping () -> Void) {
            self.chooseFolder = chooseFolder
        }

        @objc func selectItem(_ sender: NSPopUpButton) {
            let choseOther = sender.indexOfSelectedItem == 1
            sender.selectItem(at: 0)
            guard choseOther else { return }
            // Let the native menu finish closing before presenting the folder sheet.
            DispatchQueue.main.async { [weak self] in
                self?.chooseFolder()
            }
        }
    }
}
