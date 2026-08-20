import Foundation

class LocalizationManager {
    static let shared = LocalizationManager()

    static let supportedLanguages: [(code: String, name: String)] = [
        ("",        "System Default"),
        ("en",      "English"),
        ("pt",      "Português"),
        ("es",      "Español"),
        ("fr",      "Français"),
        ("de",      "Deutsch"),
        ("it",      "Italiano"),
        ("nl",      "Nederlands"),
        ("ja",      "日本語"),
        ("ko",      "한국어"),
        ("zh-Hans", "中文（简体）"),
        ("zh-Hant", "中文（繁體）"),
        ("hi",      "हिन्दी"),
    ]

    private let key = "selectedLanguageCode"
    private var bundle: Bundle = .main

    private init() { reload() }

    var selectedCode: String {
        get { UserDefaults.standard.string(forKey: key) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    func reload() {
        let code = selectedCode.isEmpty ? systemChineseCode() : selectedCode
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let b = Bundle(path: path) {
            bundle = b
        } else if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
                  let b = Bundle(path: path) {
            bundle = b
        }
    }

    // Detect zh-Hans vs zh-Hant from system locale (script tag or region)
    private func systemChineseCode() -> String {
        let lang = Locale.current.language
        let code = lang.languageCode?.identifier ?? "en"
        guard code == "zh" else { return code }
        // Check script tag first
        if let script = lang.script?.identifier {
            return script == "Hant" ? "zh-Hant" : "zh-Hans"
        }
        // Fall back to region: TW, HK, MO → Traditional
        let region = lang.region?.identifier ?? Locale.current.region?.identifier ?? ""
        return ["TW", "HK", "MO"].contains(region) ? "zh-Hant" : "zh-Hans"
    }

    func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
}

func L(_ key: String) -> String {
    LocalizationManager.shared.string(key)
}
