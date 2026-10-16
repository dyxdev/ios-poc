import AppStrings
import ContextUI
import CoreContext
import CoreIdentity
import Testing

@testable import FeatureAccount

/// El catálogo debe llegar al paquete: si una clave sale tal cual, el texto no se resolvió. La paridad EN/ES y las
/// claves usadas se comprueban aparte con `tools/check-strings.py`.
struct StringsTests {
    @Test func everyIdentityErrorMessageResolvesToText() {
        for error in [IdentityError.notConfigured, .canceled, .sessionExpired, .network, .failed] {
            #expect(AppStrings.text(error.messageKey) != error.messageKey)
        }
    }

    @Test func everyContextHasATitleAndADescription() {
        for context in [UserContext.guest, .owner, .admin] {
            #expect(AppStrings.text(context.titleKey) != context.titleKey)
            #expect(AppStrings.text(context.descriptionKey) != context.descriptionKey)
        }
    }

    @Test func formattedTextFillsItsPlaceholders() {
        #expect(AppStrings.format("venue.capacity", 80).contains("80"))
    }
}
