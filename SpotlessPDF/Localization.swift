import Foundation
import SwiftUI

enum AppLocalization {
    struct LanguageOption: Identifiable, Hashable {
        let id: String
        let title: String
    }

    private static let userOverrideLanguageKey = "spotlesspdf.userSelectedLanguage"
    static let overrideLanguageKey = "AppleLanguages"
    private static let rightToLeftLanguageCodes: Set<String> = ["ar", "he", "fa", "ur"]
    static let supportedLanguageOptions: [LanguageOption] = [
        LanguageOption(id: "ar", title: "العربية"),
        LanguageOption(id: "br", title: "Brezhoneg"),
        LanguageOption(id: "es", title: "Castellano"),
        LanguageOption(id: "cs", title: "Čeština"),
        LanguageOption(id: "cy", title: "Cymraeg"),
        LanguageOption(id: "da", title: "Dansk"),
        LanguageOption(id: "de", title: "Deutsch"),
        LanguageOption(id: "el", title: "Ελληνικά"),
        LanguageOption(id: "en", title: "English"),
        LanguageOption(id: "et", title: "Eesti"),
        LanguageOption(id: "fa", title: "فارسی"),
        LanguageOption(id: "fi", title: "Suomi"),
        LanguageOption(id: "fr", title: "Français"),
        LanguageOption(id: "ga", title: "Gaeilge"),
        LanguageOption(id: "gd", title: "Gàidhlig"),
        LanguageOption(id: "gl", title: "Galego"),
        LanguageOption(id: "he", title: "עברית"),
        LanguageOption(id: "hi", title: "हिन्दी"),
        LanguageOption(id: "hr", title: "Hrvatski"),
        LanguageOption(id: "it", title: "Italiano"),
        LanguageOption(id: "ja", title: "日本語"),
        LanguageOption(id: "ko", title: "한국어"),
        LanguageOption(id: "kw", title: "Kernewek"),
        LanguageOption(id: "lt", title: "Lietuvių"),
        LanguageOption(id: "lv", title: "Latviešu"),
        LanguageOption(id: "nb", title: "Norsk bokmål"),
        LanguageOption(id: "nl", title: "Nederlands"),
        LanguageOption(id: "pl", title: "Polski"),
        LanguageOption(id: "pt-PT", title: "Português"),
        LanguageOption(id: "ro", title: "Română"),
        LanguageOption(id: "sv", title: "Svenska"),
        LanguageOption(id: "uk", title: "Українська"),
        LanguageOption(id: "zh-Hans", title: "简体中文")
    ]

    static var overrideLanguageCode: String? {
        let firstValue = UserDefaults.standard.string(forKey: userOverrideLanguageKey) ?? ""
        return firstValue.isEmpty ? nil : firstValue
    }

    static var effectiveLanguageCode: String {
        if let overrideLanguageCode {
            return resolveLanguageCode(for: overrideLanguageCode)
        }

        return resolveLanguageCode(for: Locale.preferredLanguages.first ?? "en")
    }

    static func setOverrideLanguageCode(_ languageCode: String?) {
        let defaults = UserDefaults.standard

        if let languageCode, !languageCode.isEmpty {
            defaults.set(languageCode, forKey: userOverrideLanguageKey)
            defaults.set([languageCode], forKey: overrideLanguageKey)
        } else {
            defaults.removeObject(forKey: userOverrideLanguageKey)
            defaults.removeObject(forKey: overrideLanguageKey)
        }
    }

    static func localized(_ key: String, table: String? = nil) -> String {
        let preferredLocalization = Locale.Language(identifier: effectiveLanguageCode)
        let localizedValue = Bundle.main.localizedString(
            forKey: key,
            value: nil,
            table: table,
            localizations: [preferredLocalization]
        )
        if localizedValue != key {
            return localizedValue
        }

        let fallbackValue = Bundle.main.localizedString(
            forKey: key,
            value: nil,
            table: table,
            localizations: [Locale.Language(identifier: "en")]
        )
        if fallbackValue != key {
            return fallbackValue
        }

        return localizedValue
    }

    static var locale: Locale {
        Locale(identifier: effectiveLanguageCode)
    }

    static var layoutDirection: LayoutDirection {
        let languageCode = Locale(identifier: effectiveLanguageCode).language.languageCode?.identifier ?? "en"
        return rightToLeftLanguageCodes.contains(languageCode) ? .rightToLeft : .leftToRight
    }

    static var usesOverrideLanguage: Bool {
        overrideLanguageCode != nil
    }

    static var currentSelectionIdentifier: String {
        overrideLanguageCode ?? "system"
    }

    private static func resolveLanguageCode(for identifier: String) -> String {
        let normalizedIdentifier = identifier.replacingOccurrences(of: "_", with: "-")

        if Bundle.main.localizations.contains(normalizedIdentifier) {
            return normalizedIdentifier
        }

        let locale = Locale(identifier: normalizedIdentifier)
        if let languageCode = locale.language.languageCode?.identifier {
            if Bundle.main.localizations.contains(languageCode) {
                return languageCode
            }

            if let regionalMatch = Bundle.main.localizations.first(where: { $0.hasPrefix(languageCode + "-") }) {
                return regionalMatch
            }
        }

        return "en"
    }
}

enum L10n {
    static var appTitle: String { AppLocalization.localized("app.title") }
    static var appSubtitle: String { AppLocalization.localized("app.subtitle") }
    static var selectedPDF: String { AppLocalization.localized("card.selected_pdf") }
    static var noPDFLoaded: String { AppLocalization.localized("card.no_pdf_loaded") }
    static var changeLocation: String { AppLocalization.localized("button.change_location") }
    static var loadPDF: String { AppLocalization.localized("button.load_pdf") }
    static var clean: String { AppLocalization.localized("button.clean") }
    static var removeSelectedPDF: String { AppLocalization.localized("help.remove_selected_pdf") }
    static var appMenuAbout: String { AppLocalization.localized("menu.about") }
    static var appMenuServices: String { AppLocalization.localized("menu.services") }
    static var appMenuHide: String { AppLocalization.localized("menu.hide") }
    static var appMenuHideOthers: String { AppLocalization.localized("menu.hide_others") }
    static var appMenuShowAll: String { AppLocalization.localized("menu.show_all") }
    static var appMenuQuit: String { AppLocalization.localized("menu.quit") }
    static var languageMenuTitle: String { AppLocalization.localized("language.menu.title") }
    static var automaticLanguageMenuTitle: String { AppLocalization.localized("language.menu.automatic") }

    static func aboutVersion(_ versionNumber: String) -> String {
        String(format: AppLocalization.localized("about.version.format"), versionNumber)
    }

    static func currentDestination(_ path: String) -> String {
        String(format: AppLocalization.localized("card.current_destination"), path)
    }

    static func cleaningFailedMessage(for error: Error) -> String {
        guard let cleaningError = error as? PDFCleaningError else {
            return cleaningFailed
        }

        switch cleaningError {
        case .engineUnavailable:
            return engineUnavailableMessage
        case .engineFailed(let message):
            let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedMessage.isEmpty else {
                return cleaningFailed
            }
            return "\(cleaningFailed) \(trimmedMessage)"
        case .missingOutput:
            return missingOutputMessage
        }
    }

    private static var cleaningFailed: String { AppLocalization.localized("error.cleaning_failed") }
    private static var engineUnavailableMessage: String { AppLocalization.localized("error.engine_unavailable") }
    private static var missingOutputMessage: String { AppLocalization.localized("error.missing_output") }
}
