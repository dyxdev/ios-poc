import Foundation

/// Los eventos de analítica salen de una taxonomía cerrada y nunca llevan datos personales (ADR-IOS-0026).
public struct EventTaxonomy: Sendable {
    public enum Violation: Equatable, Sendable {
        case unknownEvent(String)
        case personalData(property: String)
    }

    public let allowedEvents: Set<String>
    public let forbiddenPropertyKeys: Set<String>

    public init(
        allowedEvents: Set<String>,
        forbiddenPropertyKeys: Set<String> = ["email", "phone", "name", "first_name", "last_name", "address"]
    ) {
        self.allowedEvents = allowedEvents
        self.forbiddenPropertyKeys = forbiddenPropertyKeys
    }

    public func validate(event: String, properties: [String: String]) -> [Violation] {
        var violations: [Violation] = []
        if !allowedEvents.contains(event) {
            violations.append(.unknownEvent(event))
        }
        for key in properties.keys.sorted() where forbiddenPropertyKeys.contains(key.lowercased()) {
            violations.append(.personalData(property: key))
        }
        return violations
    }
}
