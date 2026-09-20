import CryptoKit
import Foundation

/// Solo demo local; no es un IdP. La comparación es HMAC-SHA256 en proceso, sin red.
nonisolated struct VerificadorCredencialesDemo: VerificadorCredenciales {
    private static let claveHMACHex = "919cf51ddd83f974999c722b7c870ea018ae0a6767ea785aa9bd8aa91598fe8c"
    private static let macUsuarioHex = "6c0f832b4a36b08ff6226936e200e7acd81914d2ffd654bc74b3c0812a108acb"
    private static let macClaveHex = "c3461883b9cf66ac6b566fe239544675b0f83e10bf61dd3e6288909f1eb3adcb"

    private static let clave = SymmetricKey(data: datosHex(claveHMACHex))
    private static let macUsuario = datosHex(macUsuarioHex)
    private static let macClave = datosHex(macClaveHex)

    func verificar(_ credenciales: CredencialesInicio) async throws {
        let usuarioValido = HMAC<SHA256>.isValidAuthenticationCode(
            Self.macUsuario,
            authenticating: Data(credenciales.nombreUsuario.utf8),
            using: Self.clave
        )
        let claveValida = HMAC<SHA256>.isValidAuthenticationCode(
            Self.macClave,
            authenticating: Data(credenciales.clave.utf8),
            using: Self.clave
        )
        guard usuarioValido && claveValida else {
            throw ErrorAutenticacion.credencialesInvalidas
        }
    }

    private static func datosHex(_ hex: String) -> Data {
        var datos = Data()
        datos.reserveCapacity(hex.count / 2)
        var indice = hex.startIndex
        while indice < hex.endIndex {
            let siguiente = hex.index(indice, offsetBy: 2)
            let par = hex[indice..<siguiente]
            datos.append(UInt8(par, radix: 16) ?? 0)
            indice = siguiente
        }
        return datos
    }
}
