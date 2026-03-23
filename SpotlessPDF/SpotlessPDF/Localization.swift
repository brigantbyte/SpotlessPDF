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

    static func localized(_ key: String) -> String {
        let localizedValue = bundle.localizedString(forKey: key, value: nil, table: nil)
        if localizedValue != key {
            return localizedValue
        }

        let fallbackValue = fallbackBundle.localizedString(forKey: key, value: nil, table: nil)
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

    static func languageMenuTitle() -> String {
        switch effectiveLanguageCode {
        case "ar": return "اللغة"
        case "br": return "Yezh"
        case "cs": return "Jazyk"
        case "cy": return "Iaith"
        case "da": return "Sprog"
        case "de": return "Sprache"
        case "el": return "Γλώσσα"
        case "es": return "Idioma"
        case "et": return "Keel"
        case "fa": return "زبان"
        case "fi": return "Kieli"
        case "fr": return "Langue"
        case "ga": return "Teanga"
        case "gd": return "Cànan"
        case "gl": return "Idioma"
        case "he": return "שפה"
        case "hi": return "भाषा"
        case "hr": return "Jezik"
        case "it": return "Lingua"
        case "ja": return "言語"
        case "ko": return "언어"
        case "kw": return "Yeth"
        case "lt": return "Kalba"
        case "lv": return "Valoda"
        case "nb": return "Språk"
        case "nl": return "Taal"
        case "pl": return "Język"
        case "pt-PT": return "Idioma"
        case "ro": return "Limbă"
        case "sv": return "Språk"
        case "uk": return "Мова"
        case "zh-Hans": return "语言"
        default: return "Language"
        }
    }

    static func automaticMenuTitle() -> String {
        switch effectiveLanguageCode {
        case "ar": return "تلقائي"
        case "br": return "Emgefreek"
        case "cs": return "Automaticky"
        case "cy": return "Awtomatig"
        case "da": return "Automatisk"
        case "de": return "Automatisch"
        case "el": return "Αυτόματα"
        case "es": return "Automático"
        case "et": return "Automaatne"
        case "fa": return "خودکار"
        case "fi": return "Automaattinen"
        case "fr": return "Automatique"
        case "ga": return "Uathoibríoch"
        case "gd": return "Fèin-obrachail"
        case "gl": return "Automático"
        case "he": return "אוטומטי"
        case "hi": return "स्वचालित"
        case "hr": return "Automatski"
        case "it": return "Automatico"
        case "ja": return "自動"
        case "ko": return "자동"
        case "kw": return "Owtomatyk"
        case "lt": return "Automatinis"
        case "lv": return "Automātiski"
        case "nb": return "Automatisk"
        case "nl": return "Automatisch"
        case "pl": return "Automatyczny"
        case "pt-PT": return "Automático"
        case "ro": return "Automat"
        case "sv": return "Automatiskt"
        case "uk": return "Автоматично"
        case "zh-Hans": return "自动"
        default: return "Automatic"
        }
    }

    private static var bundle: Bundle {
        guard
            let resourcePath = Bundle.main.path(forResource: effectiveLanguageCode, ofType: "lproj"),
            let localizedBundle = Bundle(path: resourcePath)
        else {
            return .main
        }

        return localizedBundle
    }

    private static var fallbackBundle: Bundle {
        guard
            let resourcePath = Bundle.main.path(forResource: "en", ofType: "lproj"),
            let localizedBundle = Bundle(path: resourcePath)
        else {
            return .main
        }

        return localizedBundle
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
    static var cleanDownloaded: String { AppLocalization.localized("toast.clean_downloaded") }
    static var removeSelectedPDF: String { AppLocalization.localized("help.remove_selected_pdf") }
    static var appMenuAbout: String { AppLocalization.localized("menu.about") }
    static var appMenuServices: String { AppLocalization.localized("menu.services") }
    static var appMenuHide: String { AppLocalization.localized("menu.hide") }
    static var appMenuHideOthers: String { AppLocalization.localized("menu.hide_others") }
    static var appMenuShowAll: String { AppLocalization.localized("menu.show_all") }
    static var appMenuQuit: String { AppLocalization.localized("menu.quit") }

    static func aboutVersion(_ versionNumber: String) -> String {
        String(format: AppLocalization.localized("about.version.format"), versionNumber)
    }

    static func currentDestination(_ path: String) -> String {
        String(format: AppLocalization.localized("card.current_destination"), path)
    }

    static func cleaningFailedMessage(for error: Error) -> String {
        guard let cleaningError = error as? PDFCleaningError else {
            return genericCleaningFailed
        }

        switch cleaningError {
        case .engineUnavailable:
            return engineUnavailable
        case .engineFailed(let message):
            let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedMessage.isEmpty else {
                return genericCleaningFailed
            }
            return "\(genericCleaningFailed) \(trimmedMessage)"
        case .missingOutput:
            return missingOutput
        }
    }

    private static var genericCleaningFailed: String {
        switch AppLocalization.effectiveLanguageCode {
        case "ar": return "تعذر تنظيف ملف PDF."
        case "br": return "N'eus ket bet gallet naetaat ar PDF."
        case "cs": return "PDF se nepodařilo vyčistit."
        case "cy": return "Methwyd glanhau'r PDF."
        case "da": return "PDF-filen kunne ikke renses."
        case "de": return "Das PDF konnte nicht bereinigt werden."
        case "el": return "Δεν ήταν δυνατός ο καθαρισμός του PDF."
        case "es": return "No se pudo limpiar el PDF."
        case "et": return "PDF-i ei saanud puhastada."
        case "fa": return "پاک‌سازی PDF انجام نشد."
        case "fi": return "PDF-tiedostoa ei voitu puhdistaa."
        case "fr": return "Impossible de nettoyer le PDF."
        case "ga": return "Níorbh fhéidir an PDF a ghlanadh."
        case "gd": return "Cha b’ urrainn dhuinn am PDF a ghlanadh."
        case "gl": return "Non se puido limpar o PDF."
        case "he": return "לא ניתן היה לנקות את ה־PDF."
        case "hi": return "PDF साफ नहीं किया जा सका."
        case "hr": return "PDF nije moguće očistiti."
        case "it": return "Impossibile pulire il PDF."
        case "ja": return "PDFをクリーンアップできませんでした。"
        case "ko": return "PDF를 정리하지 못했습니다."
        case "kw": return "Ny yllsys glanshe PDF."
        case "lt": return "Nepavyko išvalyti PDF."
        case "lv": return "Neizdevās notīrīt PDF."
        case "nb": return "PDF-en kunne ikke renses."
        case "nl": return "De pdf kon niet worden opgeschoond."
        case "pl": return "Nie udało się oczyścić pliku PDF."
        case "pt-PT": return "Não foi possível limpar o PDF."
        case "ro": return "PDF-ul nu a putut fi curățat."
        case "sv": return "Det gick inte att rensa PDF-filen."
        case "uk": return "Не вдалося очистити PDF."
        case "zh-Hans": return "无法清理 PDF。"
        default: return "Could not clean the PDF."
        }
    }

    private static var engineUnavailable: String {
        switch AppLocalization.effectiveLanguageCode {
        case "ar": return "محرك Rust غير متاح حالياً."
        case "br": return "N'eo ket hegerz ar c'heflusker Rust c'hoazh."
        case "cs": return "Modul Rust zatím není k dispozici."
        case "cy": return "Nid yw'r peiriant Rust ar gael eto."
        case "da": return "Rust-motoren er ikke tilgængelig endnu."
        case "de": return "Die Rust-Engine ist noch nicht verfügbar."
        case "el": return "Η μηχανή Rust δεν είναι ακόμη διαθέσιμη."
        case "es": return "El motor Rust no está disponible todavía."
        case "et": return "Rusti mootor pole veel saadaval."
        case "fa": return "موتور Rust هنوز در دسترس نیست."
        case "fi": return "Rust-moottori ei ole vielä saatavilla."
        case "fr": return "Le moteur Rust n'est pas encore disponible."
        case "ga": return "Níl an t-inneall Rust ar fáil fós."
        case "gd": return "Chan eil einnsean Rust ri fhaighinn fhathast."
        case "gl": return "O motor Rust aínda non está dispoñible."
        case "he": return "מנוע Rust עדיין לא זמין."
        case "hi": return "Rust इंजन अभी उपलब्ध नहीं है."
        case "hr": return "Rust mehanizam još nije dostupan."
        case "it": return "Il motore Rust non è ancora disponibile."
        case "ja": return "Rust エンジンはまだ利用できません。"
        case "ko": return "Rust 엔진을 아직 사용할 수 없습니다."
        case "kw": return "Ny yw an injan Rust ar gael hwath."
        case "lt": return "Rust variklis dar nepasiekiamas."
        case "lv": return "Rust dzinis vēl nav pieejams."
        case "nb": return "Rust-motoren er ikke tilgjengelig ennå."
        case "nl": return "De Rust-engine is nog niet beschikbaar."
        case "pl": return "Silnik Rust nie jest jeszcze dostępny."
        case "pt-PT": return "O motor Rust ainda não está disponível."
        case "ro": return "Motorul Rust nu este încă disponibil."
        case "sv": return "Rust-motorn är inte tillgänglig ännu."
        case "uk": return "Рушій Rust ще недоступний."
        case "zh-Hans": return "Rust 引擎暂时不可用。"
        default: return "The Rust engine is not available yet."
        }
    }

    private static var missingOutput: String {
        switch AppLocalization.effectiveLanguageCode {
        case "ar": return "انتهت العملية لكن ملف PDF الناتج لم يُنشأ."
        case "br": return "Echu eo ar c'heflusker met n'eus bet krouet PDF ezhomm ebet."
        case "cs": return "Proces skončil, ale výstupní PDF nebylo vytvořeno."
        case "cy": return "Daeth y peiriant i ben, ond ni chrewyd y PDF allbwn."
        case "da": return "Motoren blev færdig, men oprettede ikke output-PDF'en."
        case "de": return "Die Engine wurde beendet, hat aber kein Ausgabe-PDF erzeugt."
        case "el": return "Η μηχανή ολοκληρώθηκε, αλλά δεν δημιούργησε το PDF εξόδου."
        case "es": return "El motor terminó, pero no generó el PDF de salida."
        case "et": return "Mootor lõpetas töö, kuid väljund-PDF-i ei loodud."
        case "fa": return "موتور تمام شد اما PDF خروجی ساخته نشد."
        case "fi": return "Moottori päättyi, mutta tulos-PDF:ää ei luotu."
        case "fr": return "Le moteur s'est terminé, mais n'a pas généré le PDF de sortie."
        case "ga": return "Chríochnaigh an t-inneall, ach níor gineadh an PDF aschuir."
        case "gd": return "Chrìochnaich an t-einnsean ach cha deach PDF toraidh a chruthachadh."
        case "gl": return "O motor rematou, pero non xerou o PDF de saída."
        case "he": return "המנוע סיים, אבל לא יצר את קובץ ה-PDF של הפלט."
        case "hi": return "इंजन समाप्त हो गया, लेकिन आउटपुट PDF नहीं बना."
        case "hr": return "Mehanizam je završio, ali nije stvorio izlazni PDF."
        case "it": return "Il motore ha terminato, ma non ha generato il PDF di output."
        case "ja": return "エンジンは終了しましたが、出力 PDF が生成されませんでした。"
        case "ko": return "엔진은 종료됐지만 출력 PDF를 만들지 못했습니다."
        case "kw": return "Gorfennys yw an injan mes ny wrug kroui an PDF dheall."
        case "lt": return "Variklis baigė darbą, tačiau neišvedė PDF failo."
        case "lv": return "Dzinis pabeidza darbu, bet neizveidoja izvades PDF."
        case "nb": return "Motoren ble ferdig, men opprettet ikke utdata-PDF-en."
        case "nl": return "De engine is klaar, maar heeft geen uitvoer-pdf gemaakt."
        case "pl": return "Silnik zakończył pracę, ale nie utworzył wynikowego pliku PDF."
        case "pt-PT": return "O motor terminou, mas não gerou o PDF de saída."
        case "ro": return "Motorul s-a încheiat, dar nu a generat PDF-ul de ieșire."
        case "sv": return "Motorn avslutades men skapade inte PDF-filen."
        case "uk": return "Рушій завершив роботу, але не створив вихідний PDF."
        case "zh-Hans": return "引擎已结束，但没有生成输出 PDF。"
        default: return "The engine finished, but did not generate the output PDF."
        }
    }
}
