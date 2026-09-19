import Foundation

nonisolated protocol ResumenUsuariosCasoUso: Sendable {
    func ejecutar(_ usuarios: [Usuario]) -> ResumenDashboard
}

nonisolated struct ResumenUsuariosServicio: ResumenUsuariosCasoUso {
    func ejecutar(_ usuarios: [Usuario]) -> ResumenDashboard {
        guard !usuarios.isEmpty else { return .vacio }

        var ciudades: [ClaveAgrupacion: Int] = [:]
        var empresas: [ClaveAgrupacion: Int] = [:]

        for usuario in usuarios {
            ciudades[Self.clave(usuario.direccion.ciudad), default: 0] += 1
            empresas[Self.clave(usuario.empresa.nombre), default: 0] += 1
        }

        return ResumenDashboard(
            totalUsuarios: usuarios.count,
            ciudadesDistintas: ciudades.keys.filter(\.esValor).count,
            empresasDistintas: empresas.keys.filter(\.esValor).count,
            usuariosSinCiudad: ciudades[.ausente, default: 0],
            usuariosSinEmpresa: empresas[.ausente, default: 0],
            usuariosPorCiudad: Self.serie(ciudades),
            usuariosPorEmpresa: Self.serie(empresas)
        )
    }

    private static func clave(_ texto: String) -> ClaveAgrupacion {
        let recorte = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        return recorte.isEmpty ? .ausente : .valor(recorte)
    }

    private static func serie(_ conteos: [ClaveAgrupacion: Int]) -> [PuntoGrafico] {
        conteos
            .filter { $0.value > 0 }
            .sorted(by: ordenEstable)
            .map { PuntoGrafico(clave: $0.key, valor: $0.value) }
    }

    private static func ordenEstable(
        _ izquierda: (key: ClaveAgrupacion, value: Int),
        _ derecha: (key: ClaveAgrupacion, value: Int)
    ) -> Bool {
        if izquierda.value != derecha.value {
            return izquierda.value > derecha.value
        }
        switch (izquierda.key, derecha.key) {
        case (.ausente, .ausente):
            return false
        case (.ausente, _):
            return false
        case (_, .ausente):
            return true
        case (.valor(let izq), .valor(let der)):
            return izq < der
        }
    }
}
