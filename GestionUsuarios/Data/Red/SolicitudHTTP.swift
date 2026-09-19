import Foundation

nonisolated enum MetodoHTTP: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

nonisolated struct SolicitudHTTP: Sendable {
    let metodo: MetodoHTTP
    let url: URL
    let cuerpo: Data?

    var esIdempotente: Bool {
        metodo == .get
    }
}
