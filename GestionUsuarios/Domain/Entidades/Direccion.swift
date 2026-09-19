import Foundation

nonisolated struct Coordenada: Sendable, Equatable, Hashable {
    var latitud: Double
    var longitud: Double
}

nonisolated struct Direccion: Sendable, Equatable, Hashable {
    var calle: String
    var apartamento: String
    var ciudad: String
    var codigoPostal: String
    var coordenada: Coordenada?

    static let vacia = Direccion(
        calle: "",
        apartamento: "",
        ciudad: "",
        codigoPostal: "",
        coordenada: nil
    )
}
