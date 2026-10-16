import Foundation

/// Textos de la app (String Catalog `Localizable.xcstrings`, EN y ES; inglés por defecto, ADR-IOS-0011). Todas las
/// features leen de aquí, así hay un solo catálogo y un solo script de paridad (`tools/check-strings.py`).
public enum AppStrings {
    public static let bundle = Bundle.module

    public static func text(_ key: String) -> String {
        NSLocalizedString(key, tableName: "Localizable", bundle: bundle, value: key, comment: "")
    }

    /// Texto con marcadores `%@`, `%d`… del catálogo.
    public static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: Locale.current, arguments: arguments)
    }
}
