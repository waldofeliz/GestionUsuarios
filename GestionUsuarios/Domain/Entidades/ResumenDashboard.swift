import Foundation

nonisolated enum ClaveAgrupacion: Sendable, Hashable, Equatable {
    case valor(String)
    case ausente

    var esValor: Bool {
        if case .valor = self { return true }
        return false
    }
}

nonisolated struct PuntoGrafico: Identifiable, Sendable, Equatable {
    let id: ClaveAgrupacion
    let clave: ClaveAgrupacion
    let valor: Int

    init(clave: ClaveAgrupacion, valor: Int) {
        self.id = clave
        self.clave = clave
        self.valor = valor
    }
}

nonisolated struct ResumenDashboard: Sendable, Equatable {
    let totalUsuarios: Int
    let ciudadesDistintas: Int
    let empresasDistintas: Int
    let usuariosSinCiudad: Int
    let usuariosSinEmpresa: Int
    let usuariosPorCiudad: [PuntoGrafico]
    let usuariosPorEmpresa: [PuntoGrafico]

    static let vacio = ResumenDashboard(
        totalUsuarios: 0,
        ciudadesDistintas: 0,
        empresasDistintas: 0,
        usuariosSinCiudad: 0,
        usuariosSinEmpresa: 0,
        usuariosPorCiudad: [],
        usuariosPorEmpresa: []
    )
}
