import AppKit
import Foundation

@main struct NativeLanguageChecks {
    @MainActor static func main() {
        let nativeLanguages = Bundle(for: NSOpenPanel.self).localizations
        func nativeChoice(_ selected: String?, system: [String]) -> String {
            let preferences = AppLocalization.nativeLanguagePreferences(
                selectedLanguage: selected, systemLanguages: system)
            return Bundle.preferredLocalizations(from: nativeLanguages, forPreferences: preferences)[0]
        }
        precondition(nativeChoice("br", system: ["es-ES"]) == "es")
        precondition(nativeChoice("br", system: ["de-DE"]) == "de")
        precondition(nativeChoice("br", system: []) == "en")
        precondition(nativeChoice("br", system: ["zz-ZZ"]) == "en")
        precondition(nativeChoice("fr", system: ["es-ES"]) == "fr")
        precondition(nativeChoice(nil, system: ["es-ES"]) == "es")
        precondition(nativeChoice(nil, system: []) == "en")
        for option in AppLocalization.supportedLanguageOptions {
            let preferences = AppLocalization.nativeLanguagePreferences(
                selectedLanguage: option.id, systemLanguages: ["es-ES", "en", "es-ES"])
            precondition(preferences.first == option.id)
            precondition(preferences.contains("en"))
            precondition(preferences.count == Set(preferences).count)
        }
        print("Passed: native AppKit fallback for Breton to system Spanish/German, final English fallback, automatic mode, and precedence for all 33 app languages.")
    }
}
