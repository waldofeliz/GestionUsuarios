import Foundation
import Testing
@testable import GestionUsuarios

struct DashboardKPIAltasYCopyTests {
    private let servicio = ResumenUsuariosServicio()

    @Test func umbralDeAltasCoincideConOverlayDeSesion() {
        #expect(UmbralOverlayUsuarios.idSintetico == UsuarioRepositorioSesion.idSinteticoMinimo)
        #expect(UmbralOverlayUsuarios.idSintetico == 10_000)
    }

    @Test func overlaySinAltasDaCeroYTrasCrearIncrementaTotalYAltas() async throws {
        let remoto = RepositorioUsuariosMemoria(usuarios: [FixturesUsuario.leanne])
        let overlay = UsuarioRepositorioSesion(remoto: remoto)

        let listaInicial = try await overlay.listar()
        let resumenInicial = servicio.ejecutar(listaInicial)
        #expect(resumenInicial.totalUsuarios == 1)
        #expect(resumenInicial.ciudadesDistintas == 1)
        #expect(resumenInicial.empresasDistintas == 1)
        #expect(altas(en: listaInicial) == 0)

        _ = try await overlay.crear(FixturesUsuario.altaValida)
        let lista = try await overlay.listar()
        let resumen = servicio.ejecutar(lista)

        #expect(resumen.totalUsuarios == 2)
        #expect(altas(en: lista) == 1)
        #expect(resumen.totalUsuarios != 6374)
        #expect(resumen.ciudadesDistintas == 1)
        #expect(resumen.empresasDistintas == 1)
    }

    @MainActor
    @Test func shellCuentaAltasSoloConIdSintetico() {
        let modelo = shellConMemoria([FixturesUsuario.leanne])
        modelo.usuarios.usuarios = [FixturesUsuario.leanne]
        modelo.usuarios.estado = .listo

        #expect(modelo.altasDeSesion == 0)
        #expect(modelo.resumen.totalUsuarios == 1)
        #expect(modelo.resumen.ciudadesDistintas == 1)
        #expect(modelo.resumen.empresasDistintas == 1)

        let alta = Usuario(
            id: UsuarioID(UmbralOverlayUsuarios.idSintetico),
            alta: FixturesUsuario.altaValida
        )
        modelo.usuarios.usuarios = [FixturesUsuario.leanne, alta]

        #expect(modelo.altasDeSesion == 1)
        #expect(modelo.resumen.totalUsuarios == 2)
        #expect(modelo.resumen.ciudadesDistintas == 1)
        #expect(modelo.resumen.empresasDistintas == 1)
    }

    @Test func copyDeDashboardNoUsaMetricasFake() {
        let textos = [
            TextosUsuarios.kpiUsuarios,
            TextosUsuarios.kpiCiudades,
            TextosUsuarios.kpiEmpresas,
            TextosUsuarios.kpiAltas,
            TextosUsuarios.chartCiudades,
            TextosUsuarios.chartEmpresas,
            TextosUsuarios.chartCiudadesA11y,
            TextosUsuarios.chartEmpresasA11y
        ]

        #expect(TextosUsuarios.chartCiudades == "Usuarios por ciudad")
        #expect(TextosUsuarios.chartEmpresas == "Usuarios por empresa")
        #expect(TextosUsuarios.kpiAltas == "Altas de sesión")

        for texto in textos {
            #expect(!texto.localizedCaseInsensitiveContains("visitas"))
            #expect(!texto.localizedCaseInsensitiveContains("traffic"))
            #expect(!texto.localizedCaseInsensitiveContains("analytics"))
            #expect(!texto.contains("6374"))
            #expect(!texto.localizedCaseInsensitiveContains("mixpro"))
        }
    }

    @Test func identifiersDeDashboardYLoginSiguenElContrato() {
        #expect(IdentificadorAccesibilidad.homeKpiUsuarios == "home.kpi.usuarios")
        #expect(IdentificadorAccesibilidad.homeKpiCiudades == "home.kpi.ciudades")
        #expect(IdentificadorAccesibilidad.homeKpiEmpresas == "home.kpi.empresas")
        #expect(IdentificadorAccesibilidad.homeKpiAltas == "home.kpi.altas")
        #expect(IdentificadorAccesibilidad.homeChartCiudades == "home.chart.ciudades")
        #expect(IdentificadorAccesibilidad.homeChartEmpresas == "home.chart.empresas")
        #expect(IdentificadorAccesibilidad.loginUsuario == "login.usuario")
        #expect(IdentificadorAccesibilidad.loginClave == "login.clave")
        #expect(IdentificadorAccesibilidad.loginEntrar == "login.entrar")
        #expect(IdentificadorAccesibilidad.homeSaludo == "home.saludo")
        #expect(IdentificadorAccesibilidad.toolbarLogout == "toolbar.logout")
    }

    @MainActor
    private func shellConMemoria(_ usuarios: [Usuario]) -> ShellVistaModelo {
        let remoto = RepositorioUsuariosMemoria(usuarios: usuarios)
        let almacen = AlmacenSesionMemoria()
        let contenedor = ContenedorApp(
            repositorio: remoto,
            iniciarSesion: IniciarSesionServicio(
                verificador: VerificadorCredencialesDemo(),
                almacen: almacen,
                intentos: RegistroIntentosMemoria()
            ),
            cerrarSesion: CerrarSesionServicio(almacen: almacen),
            sesionActual: SesionActualServicio(almacen: almacen)
        )
        return ShellVistaModelo(contenedor: contenedor)
    }

    private func altas(en usuarios: [Usuario]) -> Int {
        usuarios.filter { $0.id.valor >= UmbralOverlayUsuarios.idSintetico }.count
    }
}
