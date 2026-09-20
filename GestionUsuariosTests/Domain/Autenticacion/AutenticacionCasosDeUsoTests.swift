import Foundation
import Testing
@testable import GestionUsuarios

actor RelojControlado: RelojAutenticacion {
    private var instante: Date

    init(_ instante: Date) {
        self.instante = instante
    }

    func ahora() async -> Date {
        instante
    }

    func avanzar(segundos: TimeInterval) {
        instante = instante.addingTimeInterval(segundos)
    }
}

struct IniciarSesionCasoUsoTests {
    private let origen = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func credencialesDemoInicianSesion() async throws {
        let entorno = await fabrica()
        let sesion = try await entorno.servicio.ejecutar(
            CredencialesInicio(nombreUsuario: "  administrador  ", clave: "123456")
        )
        #expect(sesion.nombreUsuario == "administrador")
        #expect(await entorno.almacen.actual() == sesion)
    }

    @Test func claveIncorrectaNoInicia() async {
        let entorno = await fabrica()
        await #expect(throws: ErrorAutenticacion.credencialesInvalidas) {
            try await entorno.servicio.ejecutar(
                CredencialesInicio(nombreUsuario: "administrador", clave: "no")
            )
        }
        #expect(await entorno.almacen.actual() == nil)
    }

    @Test func sesionYaIniciadaSeRechaza() async throws {
        let entorno = await fabrica()
        _ = try await entorno.servicio.ejecutar(
            CredencialesInicio(nombreUsuario: "administrador", clave: "123456")
        )
        await #expect(throws: ErrorAutenticacion.sesionYaIniciada) {
            try await entorno.servicio.ejecutar(
                CredencialesInicio(nombreUsuario: "administrador", clave: "123456")
            )
        }
    }

    @Test func cincoFallosActivanLockoutDeTreintaSegundos() async throws {
        let entorno = await fabrica()
        let invalidas = CredencialesInicio(nombreUsuario: "x", clave: "y")
        for _ in 1...4 {
            await #expect(throws: ErrorAutenticacion.credencialesInvalidas) {
                try await entorno.servicio.ejecutar(invalidas)
            }
        }
        await #expect(throws: ErrorAutenticacion.cuentaBloqueada(segundosRestantes: 30)) {
            try await entorno.servicio.ejecutar(invalidas)
        }
        await #expect(throws: ErrorAutenticacion.cuentaBloqueada(segundosRestantes: 30)) {
            try await entorno.servicio.ejecutar(
                CredencialesInicio(nombreUsuario: "administrador", clave: "123456")
            )
        }

        await entorno.reloj.avanzar(segundos: 30)
        let sesion = try await entorno.servicio.ejecutar(
            CredencialesInicio(nombreUsuario: "administrador", clave: "123456")
        )
        #expect(sesion.nombreUsuario == "administrador")
    }

    @Test func exitoReiniciaContadorDeFallos() async throws {
        let entorno = await fabrica()
        let invalidas = CredencialesInicio(nombreUsuario: "x", clave: "y")
        for _ in 1...4 {
            await #expect(throws: ErrorAutenticacion.credencialesInvalidas) {
                try await entorno.servicio.ejecutar(invalidas)
            }
        }
        _ = try await entorno.servicio.ejecutar(
            CredencialesInicio(nombreUsuario: "administrador", clave: "123456")
        )
        await entorno.almacen.borrar()

        for _ in 1...4 {
            await #expect(throws: ErrorAutenticacion.credencialesInvalidas) {
                try await entorno.servicio.ejecutar(invalidas)
            }
        }
        await #expect(throws: ErrorAutenticacion.cuentaBloqueada(segundosRestantes: 30)) {
            try await entorno.servicio.ejecutar(invalidas)
        }
    }

    private func fabrica() async -> (
        almacen: AlmacenSesionMemoria,
        servicio: IniciarSesionServicio,
        reloj: RelojControlado
    ) {
        let almacen = AlmacenSesionMemoria()
        let reloj = RelojControlado(origen)
        let servicio = IniciarSesionServicio(
            verificador: VerificadorCredencialesDemo(),
            almacen: almacen,
            intentos: RegistroIntentosMemoria(),
            reloj: reloj
        )
        return (almacen, servicio, reloj)
    }
}

struct CerrarSesionYGateTests {
    @Test func sinSesionElGateLanzaSesionRequerida() async {
        let remoto = RepositorioUsuariosMemoria(usuarios: [FixturesUsuario.leanne])
        let autorizado = UsuarioRepositorioAutorizado(
            base: remoto,
            proveedor: ProveedorSesionFijo(hay: false)
        )
        await #expect(throws: ErrorAutenticacion.sesionRequerida) {
            try await autorizado.listar()
        }
        await #expect(throws: ErrorAutenticacion.sesionRequerida) {
            try await autorizado.obtener(id: UsuarioID(1))
        }
        await #expect(throws: ErrorAutenticacion.sesionRequerida) {
            try await autorizado.crear(FixturesUsuario.altaValida)
        }
        await #expect(throws: ErrorAutenticacion.sesionRequerida) {
            try await autorizado.actualizar(FixturesUsuario.leanne)
        }
        #expect(remoto.llamadasListar == 0)
        #expect(remoto.llamadasCrear == 0)
    }

    @Test func conSesionElGateDelega() async throws {
        let remoto = RepositorioUsuariosMemoria(usuarios: [FixturesUsuario.leanne])
        let autorizado = UsuarioRepositorioAutorizado(
            base: remoto,
            proveedor: ProveedorSesionFijo(hay: true)
        )
        let lista = try await autorizado.listar()
        #expect(lista.count == 1)
        #expect(remoto.llamadasListar == 1)
    }

    @Test func overlaySeReiniciaEnLogoutCompuesto() async throws {
        let remoto = RepositorioUsuariosMemoria(usuarios: [FixturesUsuario.leanne])
        let overlay = UsuarioRepositorioSesion(remoto: remoto)
        let creado = try await overlay.crear(FixturesUsuario.altaValida)
        #expect(creado.id.valor == UsuarioRepositorioSesion.idSinteticoMinimo)

        let almacen = AlmacenSesionMemoria()
        await almacen.guardar(Sesion(nombreUsuario: "demo", iniciadaEn: Date()))
        let compuesto = CerrarSesionCompuesto(
            dominio: CerrarSesionServicio(almacen: almacen),
            overlay: overlay
        )

        await compuesto.ejecutar()

        #expect(await almacen.actual() == nil)
        let lista = try await overlay.listar()
        #expect(lista.map(\.id) == [UsuarioID(1)])

        let siguiente = try await overlay.crear(FixturesUsuario.altaValida)
        #expect(siguiente.id.valor == UsuarioRepositorioSesion.idSinteticoMinimo)
    }
}

nonisolated struct ProveedorSesionFijo: ProveedorSesionActiva {
    let hay: Bool

    func haySesion() async -> Bool {
        hay
    }
}
