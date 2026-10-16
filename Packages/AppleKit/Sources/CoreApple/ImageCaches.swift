import Foundation
import Nuke

/// Al cerrar sesión se vacían las cachés de imágenes de Nuke, en memoria y en disco (ADR-IOS-0024): las fotos de datos
/// privados no deben sobrevivir a la sesión.
public enum ImageCaches {
    public static func clearAll() async {
        ImagePipeline.shared.cache.removeAll()
        DataLoader.sharedUrlCache.removeAllCachedResponses()
    }
}
