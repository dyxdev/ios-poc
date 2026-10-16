import OSLog

/// Registro con `Logger` (ADR-IOS-0016: sin `print` ni `NSLog`). Nunca se registran tokens ni datos personales
/// (ADR-IOS-0004 y 0014): solo clases de error y eventos sin contenido.
public enum Log {
    public static let identity = Logger(subsystem: "com.venuenexa.pocios", category: "identity")
    public static let network = Logger(subsystem: "com.venuenexa.pocios", category: "network")
    public static let upload = Logger(subsystem: "com.venuenexa.pocios", category: "upload")
}
