import Foundation

nonisolated protocol ClienteHTTP: Sendable {
    func enviar(_ solicitud: SolicitudHTTP) async throws -> RespuestaHTTP
}
