import Foundation
import SwiftUI

@MainActor
protocol ContenedorDependencias: AnyObject {
    var listarUsuarios: ListarUsuariosCasoUso { get }
    var obtenerUsuario: ObtenerUsuarioCasoUso { get }
    var crearUsuario: CrearUsuarioCasoUso { get }
    var actualizarUsuario: ActualizarUsuarioCasoUso { get }

    var iniciarSesion: IniciarSesionCasoUso { get }
    var cerrarSesion: CerrarSesionCasoUso { get }
    var sesionActual: SesionActualCasoUso { get }

    var sesion: Sesion? { get }
    var resumenUsuarios: ResumenUsuariosCasoUso { get }

    func refrescarSesion() async
}

private struct ClaveContenedorDependencias: EnvironmentKey {
    static let defaultValue: (any ContenedorDependencias)? = nil
}

extension EnvironmentValues {
    var contenedorDependencias: (any ContenedorDependencias)? {
        get { self[ClaveContenedorDependencias.self] }
        set { self[ClaveContenedorDependencias.self] = newValue }
    }
}

@MainActor
final class ContenedorApp: ContenedorDependencias {
    let listarUsuarios: ListarUsuariosCasoUso
    let obtenerUsuario: ObtenerUsuarioCasoUso
    let crearUsuario: CrearUsuarioCasoUso
    let actualizarUsuario: ActualizarUsuarioCasoUso
    let iniciarSesion: IniciarSesionCasoUso
    let cerrarSesion: CerrarSesionCasoUso
    let sesionActual: SesionActualCasoUso
    let resumenUsuarios: ResumenUsuariosCasoUso
    var sesion: Sesion?

    init(
        repositorio: any UsuarioRepositorio,
        iniciarSesion: any IniciarSesionCasoUso,
        cerrarSesion: any CerrarSesionCasoUso,
        sesionActual: any SesionActualCasoUso
    ) {
        self.listarUsuarios = ListarUsuariosServicio(repositorio: repositorio)
        self.obtenerUsuario = ObtenerUsuarioServicio(repositorio: repositorio)
        self.crearUsuario = CrearUsuarioServicio(repositorio: repositorio)
        self.actualizarUsuario = ActualizarUsuarioServicio(repositorio: repositorio)
        self.iniciarSesion = iniciarSesion
        self.cerrarSesion = cerrarSesion
        self.sesionActual = sesionActual
        self.resumenUsuarios = ResumenUsuariosServicio()
        self.sesion = nil
    }

    convenience init() {
        let configuracion = URLSessionConfiguration.ephemeral
        configuracion.waitsForConnectivity = false
        configuracion.timeoutIntervalForRequest = 15
        configuracion.timeoutIntervalForResource = 15
        let sesionHTTP = URLSession(configuration: configuracion)
        let cliente = ClienteHTTPURLSession(sesion: sesionHTTP)
        let api = APIUsuariosJSONPlaceholder(cliente: cliente)
        let remoto = UsuarioRepositorioRemoto(fuente: api)
        let overlay = UsuarioRepositorioSesion(remoto: remoto)
        let almacen = AlmacenSesionMemoria()
        let verificador = VerificadorCredencialesDemo()
        let autorizado = UsuarioRepositorioAutorizado(base: overlay, proveedor: almacen)
        let intentos = RegistroIntentosMemoria()
        let iniciar = IniciarSesionServicio(
            verificador: verificador,
            almacen: almacen,
            intentos: intentos
        )
        let actual = SesionActualServicio(almacen: almacen)
        let compuesto = CerrarSesionCompuesto(
            dominio: CerrarSesionServicio(almacen: almacen),
            overlay: overlay
        )
        self.init(
            repositorio: autorizado,
            iniciarSesion: iniciar,
            cerrarSesion: compuesto,
            sesionActual: actual
        )
    }

    func refrescarSesion() async {
        sesion = await sesionActual.ejecutar()
    }
}
