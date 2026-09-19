import Foundation
import Testing
@testable import GestionUsuarios

struct ResumenUsuariosCasoUsoTests {
    private let servicio = ResumenUsuariosServicio()

    @Test func listaVacia() {
        let resumen = servicio.ejecutar([])
        #expect(resumen == .vacio)
        #expect(resumen.totalUsuarios == 0)
        #expect(resumen.ciudadesDistintas == 0)
        #expect(resumen.empresasDistintas == 0)
        #expect(resumen.usuariosPorCiudad.isEmpty)
        #expect(resumen.usuariosPorEmpresa.isEmpty)
    }

    @Test func unUsuarioSinCiudadNiEmpresa() {
        let resumen = servicio.ejecutar([usuario(id: 1, ciudad: "  ", empresa: "")])
        #expect(resumen.totalUsuarios == 1)
        #expect(resumen.ciudadesDistintas == 0)
        #expect(resumen.empresasDistintas == 0)
        #expect(resumen.usuariosSinCiudad == 1)
        #expect(resumen.usuariosSinEmpresa == 1)
        #expect(resumen.usuariosPorCiudad == [PuntoGrafico(clave: .ausente, valor: 1)])
        #expect(resumen.usuariosPorEmpresa == [PuntoGrafico(clave: .ausente, valor: 1)])
    }

    @Test func dosCiudadesYTrim() {
        let resumen = servicio.ejecutar([
            usuario(id: 1, ciudad: "  Gwenborough ", empresa: "Romaguera-Crona"),
            usuario(id: 2, ciudad: "Wisokyburgh", empresa: "Deckow-Crist"),
            usuario(id: 3, ciudad: "Gwenborough", empresa: "Romaguera-Crona")
        ])
        #expect(resumen.totalUsuarios == 3)
        #expect(resumen.ciudadesDistintas == 2)
        #expect(resumen.empresasDistintas == 2)
        #expect(resumen.usuariosSinCiudad == 0)
        #expect(resumen.usuariosPorCiudad.map(\.clave) == [
            .valor("Gwenborough"),
            .valor("Wisokyburgh")
        ])
        #expect(resumen.usuariosPorCiudad.map(\.valor) == [2, 1])
        #expect(resumen.usuariosPorEmpresa.first?.clave == .valor("Romaguera-Crona"))
        #expect(resumen.usuariosPorEmpresa.first?.valor == 2)
    }

    @Test func empateDeConteoOrdenLexicograficoYAusenteAlFinal() {
        let resumen = servicio.ejecutar([
            usuario(id: 1, ciudad: "Beta", empresa: "Zeta"),
            usuario(id: 2, ciudad: "Alfa", empresa: "Zeta"),
            usuario(id: 3, ciudad: "", empresa: "Zeta")
        ])
        #expect(resumen.usuariosPorCiudad.map(\.clave) == [
            .valor("Alfa"),
            .valor("Beta"),
            .ausente
        ])
        #expect(resumen.usuariosPorCiudad.map(\.valor) == [1, 1, 1])
        #expect(resumen.ciudadesDistintas == 2)
        #expect(resumen.usuariosSinCiudad == 1)
    }

    @Test func sumaDeSeriesIgualAlTotal() {
        let usuarios = [
            usuario(id: 1, ciudad: "Gwenborough", empresa: "A"),
            usuario(id: 2, ciudad: "", empresa: "B"),
            usuario(id: 3, ciudad: "Wisokyburgh", empresa: ""),
            usuario(id: 4, ciudad: "Gwenborough", empresa: "A")
        ]
        let resumen = servicio.ejecutar(usuarios)
        #expect(resumen.totalUsuarios == 4)
        #expect(resumen.usuariosPorCiudad.reduce(0) { $0 + $1.valor } == resumen.totalUsuarios)
        #expect(resumen.usuariosPorEmpresa.reduce(0) { $0 + $1.valor } == resumen.totalUsuarios)
    }

    @Test func overlaySinteticoCuentaIgualQueRemoto() {
        let remoto = usuario(id: 1, ciudad: "Gwenborough", empresa: "Romaguera-Crona")
        let sintetico = usuario(id: 10_000, ciudad: "Gwenborough", empresa: "Romaguera-Crona")
        let resumen = servicio.ejecutar([remoto, sintetico])
        #expect(resumen.totalUsuarios == 2)
        #expect(resumen.ciudadesDistintas == 1)
        #expect(resumen.empresasDistintas == 1)
        #expect(resumen.usuariosPorCiudad == [PuntoGrafico(clave: .valor("Gwenborough"), valor: 2)])
        #expect(resumen.usuariosPorEmpresa == [PuntoGrafico(clave: .valor("Romaguera-Crona"), valor: 2)])
    }

    @Test func fixtureLeanne() {
        let resumen = servicio.ejecutar([FixturesUsuario.leanne])
        #expect(resumen.totalUsuarios == 1)
        #expect(resumen.ciudadesDistintas == 1)
        #expect(resumen.empresasDistintas == 1)
        #expect(resumen.usuariosPorCiudad.first?.clave == .valor("Gwenborough"))
        #expect(resumen.usuariosPorEmpresa.first?.clave == .valor("Romaguera-Crona"))
    }

    private func usuario(id: Int, ciudad: String, empresa: String) -> Usuario {
        Usuario(
            id: UsuarioID(id),
            nombre: "Nombre \(id)",
            nombreUsuario: "user\(id)",
            correo: "user\(id)@example.com",
            direccion: Direccion(
                calle: "",
                apartamento: "",
                ciudad: ciudad,
                codigoPostal: "",
                coordenada: nil
            ),
            empresa: Empresa(nombre: empresa, eslogan: "", rubro: "")
        )
    }
}
