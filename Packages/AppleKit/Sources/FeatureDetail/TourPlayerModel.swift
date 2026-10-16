#if canImport(AVFoundation)
    import AVFoundation
    import Foundation
    import Observation

    /// Reproductor del tour con AVPlayer propio (ADR-IOS-0029 y 0027): HLS estándar, sin SDK del proveedor.
    /// El player se crea al pulsar el póster y se libera al salir; al pasar la app a segundo plano se pausa. No añade
    /// ninguna cabecera: la petición de vídeo nunca lleva el token de acceso de la sesión.
    @MainActor
    @Observable
    public final class TourPlayerModel {
        public private(set) var player: AVPlayer?

        public init() {}

        public func start(url: URL) {
            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            self.player = player
            player.play()
        }

        public func pause() {
            player?.pause()
        }

        public func stop() {
            player?.pause()
            player?.replaceCurrentItem(with: nil)
            player = nil
        }
    }
#endif
