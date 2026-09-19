import Foundation
import Testing
@testable import GestionUsuarios

struct VerificadorCredencialesDemoTests {
    private let verificador = VerificadorCredencialesDemo()

    @Test func credencialesDemoValidas() async throws {
        try await verificador.verificar(
            CredencialesInicio(nombreUsuario: "waldofeliz", clave: "123456")
        )
    }

    @Test func credencialesBasuraInvalidas() async {
        await #expect(throws: ErrorAutenticacion.credencialesInvalidas) {
            try await verificador.verificar(
                CredencialesInicio(nombreUsuario: "nadie", clave: "basura")
            )
        }
    }

    @Test func usuarioValidoClaveBasura() async {
        await #expect(throws: ErrorAutenticacion.credencialesInvalidas) {
            try await verificador.verificar(
                CredencialesInicio(nombreUsuario: "waldofeliz", clave: "000000")
            )
        }
    }

    @Test func claveSinTrim() async {
        await #expect(throws: ErrorAutenticacion.credencialesInvalidas) {
            try await verificador.verificar(
                CredencialesInicio(nombreUsuario: "waldofeliz", clave: "123456 ")
            )
        }
    }

    @Test func usuarioLiteralNoCoincideSinHMAC() async {
        await #expect(throws: ErrorAutenticacion.credencialesInvalidas) {
            try await verificador.verificar(
                CredencialesInicio(nombreUsuario: "Waldofeliz", clave: "123456")
            )
        }
    }
}
