import Foundation

nonisolated struct RespuestaHTTP: Sendable {
    let codigo: Int
    let cuerpo: Data

    var esExitosa: Bool {
        (200...299).contains(codigo)
    }
}
