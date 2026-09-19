import Foundation

nonisolated struct PoliticaIntentosAutenticacion: Sendable {
    var maximosFallos: Int
    var segundosBloqueo: TimeInterval

    static let demo = PoliticaIntentosAutenticacion(maximosFallos: 5, segundosBloqueo: 30)
}

nonisolated protocol ControlIntentosAutenticacion: Sendable {
    func segundosRestantes(ahora: Date) async -> Int?
    func registrarFallo(ahora: Date) async -> Int?
    func registrarExito() async
}
