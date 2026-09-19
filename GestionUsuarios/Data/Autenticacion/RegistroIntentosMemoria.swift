import Foundation

actor RegistroIntentosMemoria: ControlIntentosAutenticacion {
    private var fallos = 0
    private var bloqueadoHasta: Date?
    private let politica: PoliticaIntentosAutenticacion

    init(politica: PoliticaIntentosAutenticacion = .demo) {
        self.politica = politica
    }

    func segundosRestantes(ahora: Date) async -> Int? {
        limpiarSiExpiro(ahora: ahora)
        guard let hasta = bloqueadoHasta else { return nil }
        let resto = hasta.timeIntervalSince(ahora)
        guard resto > 0 else { return nil }
        return Int(ceil(resto))
    }

    func registrarFallo(ahora: Date) async -> Int? {
        if let restantes = await segundosRestantes(ahora: ahora), restantes > 0 {
            return restantes
        }
        fallos += 1
        guard fallos >= politica.maximosFallos else { return nil }
        bloqueadoHasta = ahora.addingTimeInterval(politica.segundosBloqueo)
        return Int(ceil(politica.segundosBloqueo))
    }

    func registrarExito() async {
        fallos = 0
        bloqueadoHasta = nil
    }

    private func limpiarSiExpiro(ahora: Date) {
        guard let hasta = bloqueadoHasta else { return }
        if hasta.timeIntervalSince(ahora) <= 0 {
            bloqueadoHasta = nil
            fallos = 0
        }
    }
}
