import Foundation

struct PuntoGraficoVista: Identifiable, Equatable {
    let id: String
    let etiqueta: String
    let valor: Int
    let indice: Int
}

enum SerieGraficoPresentacion {
    static let maxCategorias = 8

    static func visibles(_ serie: [PuntoGrafico]) -> [PuntoGraficoVista] {
        let nombrados: [(String, Int)] = serie.compactMap { punto in
            switch punto.clave {
            case .valor(let nombre):
                return (nombre, punto.valor)
            case .ausente:
                return nil
            }
        }
        let recortados: [(String, Int)]
        if nombrados.count > maxCategorias {
            let cabeza = nombrados.prefix(7)
            let cola = nombrados.dropFirst(7)
            let suma = cola.reduce(0) { $0 + $1.1 }
            recortados = Array(cabeza) + [(TextosUsuarios.chartOtras(cola.count), suma)]
        } else {
            recortados = nombrados
        }
        return recortados.enumerated().map { indice, par in
            PuntoGraficoVista(
                id: "\(indice)-\(par.0)",
                etiqueta: par.0,
                valor: par.1,
                indice: indice
            )
        }
    }
}

enum EstadoValorKPI {
    case cargando
    case noDisponible
    case numero
}
