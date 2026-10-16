import CoreModel
import Foundation

/// URL de la imagen con el ancho que toca (ADR-IOS-0024: el menor ancho del conjunto cerrado que cubra los píxeles
/// reales del espacio). Hoy las fotos son de Unsplash y el ancho va en `w`; con el CDN real, la API ofrecerá las
/// renditions y esta función cambiará de sitio sin tocar a las pantallas.
public enum RenditionURL {
    public static func make(for base: URL, points: Double, scale: Double) -> URL {
        let width = ImageRendition.width(forPoints: points, scale: scale)
        guard var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else { return base }
        components.queryItems = [
            URLQueryItem(name: "auto", value: "format"),
            URLQueryItem(name: "fit", value: "crop"),
            URLQueryItem(name: "w", value: String(width)),
            URLQueryItem(name: "q", value: "70"),
        ]
        return components.url ?? base
    }
}
