import Foundation

nonisolated protocol RelojAutenticacion: Sendable {
    func ahora() async -> Date
}

nonisolated struct RelojSistema: RelojAutenticacion {
    func ahora() async -> Date {
        Date.now
    }
}
