import Foundation

/// Formato de precio y valoración según el idioma. Los precios de ejemplo son en euros por día.
public enum Formatters {
    public static func price(_ amount: Int, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        // Mínimo y máximo: en Linux (swift-corelibs) la moneda conserva 2 decimales mínimos si solo se limita el
        // máximo.
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) €"
    }

    /// «4,9 (212)»: la valoración con un decimal y el número de opiniones.
    public static func rating(_ rating: Double, reviewCount: Int, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        let value = formatter.string(from: NSNumber(value: rating)) ?? String(rating)
        return "\(value) (\(reviewCount))"
    }
}
