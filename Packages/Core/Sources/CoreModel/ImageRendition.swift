import Foundation

/// Anchos de imagen que ofrece el backend (ADR-IOS-0024, D-08). El 160 y «solo JPEG» siguen pendientes
/// de revisión de Andy en el ADR: aquí solo están los cuatro decididos.
public enum ImageRendition {
    public static let widths: [Int] = [320, 640, 960, 1440]

    /// El menor ancho que cubre los píxeles reales del espacio (puntos × escala); si necesita más que el
    /// mayor, el mayor. Así no se descarga más del doble de lo necesario (saltos de 2× como máximo).
    public static func width(forPoints points: Double, scale: Double) -> Int {
        let pixels = points * scale
        return widths.first { Double($0) >= pixels } ?? widths[widths.count - 1]
    }
}
