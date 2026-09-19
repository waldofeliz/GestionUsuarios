import Foundation

nonisolated enum MapeadorErrorRed {
    static func mapear(_ error: Error) -> ErrorUsuario {
        if error is CancellationError {
            return .red(.cancelado)
        }
        if let usuario = error as? ErrorUsuario {
            return usuario
        }
        guard let urlError = error as? URLError else {
            return .inesperado
        }
        switch urlError.code {
        case .notConnectedToInternet,
             .networkConnectionLost,
             .dnsLookupFailed,
             .cannotFindHost,
             .cannotConnectToHost,
             .dataNotAllowed:
            return .red(.sinConexion)
        case .timedOut:
            return .red(.tiempoAgotado)
        case .cancelled:
            return .red(.cancelado)
        default:
            return .inesperado
        }
    }
}
