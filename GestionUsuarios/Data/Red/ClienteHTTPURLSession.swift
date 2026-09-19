import Foundation
import os

nonisolated struct ClienteHTTPURLSession: ClienteHTTP {
    private let sesion: URLSession
    private static let timeout: TimeInterval = 15
    private static let registro = Logger(
        subsystem: "com.devapp.GestionUsuarios",
        category: "red"
    )

    init(sesion: URLSession) {
        self.sesion = sesion
    }

    func enviar(_ solicitud: SolicitudHTTP) async throws -> RespuestaHTTP {
        do {
            return try await ejecutar(solicitud)
        } catch let error as ErrorUsuario {
            if solicitud.esIdempotente, case .red(.tiempoAgotado) = error {
                return try await ejecutar(solicitud)
            }
            throw error
        }
    }

    private func ejecutar(_ solicitud: SolicitudHTTP) async throws -> RespuestaHTTP {
        var request = URLRequest(url: solicitud.url)
        request.httpMethod = solicitud.metodo.rawValue
        request.timeoutInterval = Self.timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let cuerpo = solicitud.cuerpo {
            request.httpBody = cuerpo
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        do {
            let (datos, respuesta) = try await sesion.data(for: request)
            guard let http = respuesta as? HTTPURLResponse else {
                throw ErrorUsuario.inesperado
            }
            #if DEBUG
            Self.registro.debug("HTTP \(http.statusCode, privacy: .public)")
            #endif
            return RespuestaHTTP(codigo: http.statusCode, cuerpo: datos)
        } catch {
            let mapeado = MapeadorErrorRed.mapear(error)
            #if DEBUG
            Self.registro.error("Fallo de transporte")
            #endif
            throw mapeado
        }
    }
}
