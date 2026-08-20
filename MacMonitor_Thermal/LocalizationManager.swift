import Foundation

class LocalizationManager {
    static let shared = LocalizationManager()

    static let supportedLanguages: [(code: String, name: String)] = [
        ("",   "System Default"),
        ("en", "English"),
        ("pt", "Português"),
        ("es", "Español"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("ja", "日本語"),
        ("ko", "한국어"),
        ("zh", "中文"),
        ("hi", "हिन्दी"),
    ]

    private let key = "selectedLanguageCode"
    private var bundle: Bundle = .main

    private init() { reload() }

    var selectedCode: String {
        get { UserDefaults.standard.string(forKey: key) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    func reload() {
        let code = selectedCode.isEmpty
            ? (Locale.current.language.languageCode?.identifier ?? "en")
            : selectedCode
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let b = Bundle(path: path) {
            bundle = b
        } else if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
                  let b = Bundle(path: path) {
            bundle = b
        }
    }

    func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
}

func L(_ key: String) -> String {
    LocalizationManager.shared.string(key)
}
