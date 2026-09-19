import Foundation

nonisolated struct Empresa: Sendable, Equatable, Hashable {
    var nombre: String
    var eslogan: String
    var rubro: String

    static let vacia = Empresa(nombre: "", eslogan: "", rubro: "")
}
