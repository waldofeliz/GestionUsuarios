import Foundation

nonisolated protocol VerificadorCredenciales: Sendable {
    func verificar(_ credenciales: CredencialesInicio) async throws
}
