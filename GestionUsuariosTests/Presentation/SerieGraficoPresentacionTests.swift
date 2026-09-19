import Foundation
import Testing
@testable import GestionUsuarios

struct SerieGraficoPresentacionTests {
    @Test func omiteClaveAusenteYConservaCiudadesReales() {
        let serie = [
            PuntoGrafico(clave: .valor("Gwenborough"), valor: 2),
            PuntoGrafico(clave: .ausente, valor: 1),
            PuntoGrafico(clave: .valor("Wisokyburgh"), valor: 1)
        ]

        let visibles = SerieGraficoPresentacion.visibles(serie)

        #expect(visibles.map(\.etiqueta) == ["Gwenborough", "Wisokyburgh"])
        #expect(visibles.map(\.valor) == [2, 1])
        #expect(visibles.map(\.indice) == [0, 1])
    }

    @Test func noAgregaOtrasSiHayOchoOMenos() {
        let serie = (0..<8).map { indice in
            PuntoGrafico(clave: .valor("Ciudad \(indice)"), valor: 1)
        }

        let visibles = SerieGraficoPresentacion.visibles(serie)

        #expect(visibles.count == 8)
        #expect(visibles.allSatisfy { !$0.etiqueta.hasPrefix("Otras") })
    }

    @Test func recortaAOchoCategoriasConSumaRealDeOtras() {
        let serie = (0..<9).map { indice in
            PuntoGrafico(clave: .valor("Ciudad \(indice)"), valor: 10 - indice)
        }

        let visibles = SerieGraficoPresentacion.visibles(serie)

        #expect(visibles.count == SerieGraficoPresentacion.maxCategorias)
        #expect(visibles.prefix(7).map(\.etiqueta) == (0..<7).map { "Ciudad \($0)" })
        #expect(visibles.last?.etiqueta == TextosUsuarios.chartOtras(2))
        #expect(visibles.last?.valor == 5)
        #expect(visibles.reduce(0) { $0 + $1.valor } == serie.filter(\.clave.esValor).reduce(0) { $0 + $1.valor })
    }

    @Test func resumenAccesibleUsaTituloYParesReales() {
        let puntos = SerieGraficoPresentacion.visibles([
            PuntoGrafico(clave: .valor("Gwenborough"), valor: 2),
            PuntoGrafico(clave: .valor("Wisokyburgh"), valor: 1)
        ])
        let resumen = TextosUsuarios.resumenGrafico(
            prefijo: TextosUsuarios.chartCiudadesA11y,
            puntos: puntos.map { (nombre: $0.etiqueta, valor: $0.valor) }
        )

        #expect(resumen.hasPrefix("Usuarios por ciudad."))
        #expect(resumen.contains("Gwenborough: 2"))
        #expect(resumen.contains("Wisokyburgh: 1"))
        #expect(!resumen.localizedCaseInsensitiveContains("visitas"))
        #expect(!resumen.localizedCaseInsensitiveContains("traffic"))
    }
}
