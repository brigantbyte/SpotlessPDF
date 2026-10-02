import AppKit
import Foundation

@main struct DestinationFolderPickerChecks {
    @MainActor static func main() {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        button.addItems(withTitles: ["Descargas", "Otra…"])
        var requests = 0
        let coordinator = DestinationFolderPicker.Coordinator { requests += 1 }
        coordinator.selectItem(button)
        precondition(requests == 0)
        for expected in 1...3 {
            button.selectItem(at: 1)
            coordinator.selectItem(button)
            precondition(button.indexOfSelectedItem == 0, "Other must never remain selected")
            precondition(requests == expected - 1, "The folder sheet must wait until menu tracking ends")
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
            precondition(requests == expected)
            precondition(button.selectedItem?.title == "Descargas")
        }
        print("Passed: current folder stays selected, Other is deferred, and repeated selection works.")
    }
}
