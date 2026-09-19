import Foundation
import SwiftUI

enum EstadoCargaLista: Equatable {
    case cargando
    case listo
    case error(ErrorUsuario)
}

@Observable
final class UsuariosVistaModelo {
    let coordinador = CoordinadorUsuarios()
    private let listarUsuarios: ListarUsuariosCasoUso
    private let crearUsuario: CrearUsuarioCasoUso
    private let actualizarUsuario: ActualizarUsuarioCasoUso

    var usuarios: [Usuario] = []
    var consulta = ""
    var estado: EstadoCargaLista = .cargando
    var recargando = false
    var bannerRecarga: ErrorUsuario?
    var borradorAlta = BorradorUsuario()
    var borradorEdicion = BorradorUsuario()
    var erroresAlta: [CampoUsuario: String] = [:]
    var erroresEdicion: [CampoUsuario: String] = [:]
    var validacionEnVivoAlta = false
    var validacionEnVivoEdicion = false
    var alertaGuardar = false
    var campoFocoAlta: CampoUsuario?
    var campoFocoEdicion: CampoUsuario?

    var alCrearUsuario: (() -> Void)?

    private var tareaAnuncioBusqueda: Task<Void, Never>?
    private var cargaGeneracion = 0

    init(contenedor: any ContenedorDependencias) {
        self.listarUsuarios = contenedor.listarUsuarios
        self.crearUsuario = contenedor.crearUsuario
        self.actualizarUsuario = contenedor.actualizarUsuario
    }

    var usuariosFiltrados: [Usuario] {
        filtrar(usuarios, consulta: consulta)
    }

    var usuarioSeleccionado: Usuario? {
        guard let id = coordinador.seleccion else { return nil }
        return usuarios.first { $0.id == id }
    }

    var tituloVentana: String {
        TextosUsuarios.tituloVentana(nombre: usuarioSeleccionado?.nombre)
    }

    var hayCambiosEdicion: Bool {
        guard coordinador.modoDetalle == .edicion, let usuario = usuarioSeleccionado else {
            return false
        }
        return !borradorEdicion.coincide(con: usuario)
    }

    var hayCambiosAlta: Bool {
        !borradorAlta.estaVacio
    }

    var puedeNuevo: Bool { !coordinador.mostrandoAlta }
    var puedeGuardar: Bool {
        coordinador.mostrandoAlta || coordinador.modoDetalle == .edicion
    }
    var puedeEditar: Bool {
        coordinador.seleccion != nil && !coordinador.mostrandoAlta
    }
    var puedeVerDetalle: Bool { coordinador.seleccion != nil }
    var puedeRecargar: Bool { !coordinador.hayDialogoBloqueante }

    var bindingSeleccion: Binding<UsuarioID?> {
        Binding(
            get: { self.coordinador.seleccion },
            set: { self.intentarSeleccionar($0) }
        )
    }

    func cargarInicial() async {
        await cargar(forzarVacio: usuarios.isEmpty)
    }

    func recargar() {
        guard puedeRecargar else { return }
        if hayCambiosEdicion {
            coordinador.pendiente = .recargar
            coordinador.alertaDescartar = true
            return
        }
        Task { await cargar(forzarVacio: false) }
    }

    func abrirAlta() {
        guard puedeNuevo else { return }
        borradorAlta = BorradorUsuario()
        erroresAlta = [:]
        validacionEnVivoAlta = false
        campoFocoAlta = .nombre
        coordinador.mostrandoAlta = true
    }

    func intentarCerrarAlta() {
        if hayCambiosAlta {
            coordinador.pendiente = .cerrarAlta
            coordinador.alertaDescartar = true
            return
        }
        cerrarAlta()
    }

    func entrarEdicion() {
        guard let usuario = usuarioSeleccionado else { return }
        borradorEdicion = BorradorUsuario(usuario: usuario)
        erroresEdicion = [:]
        validacionEnVivoEdicion = false
        campoFocoEdicion = .nombre
        coordinador.modoDetalle = .edicion
    }

    func intentarCancelarEdicion() {
        if hayCambiosEdicion {
            coordinador.pendiente = .cancelarEdicion
            coordinador.alertaDescartar = true
            return
        }
        salirEdicion()
    }

    func verDetalle() {
        guard puedeVerDetalle else { return }
        if hayCambiosEdicion {
            coordinador.pendiente = .verDetalle
            coordinador.alertaDescartar = true
            return
        }
        coordinador.modoDetalle = .lectura
        coordinador.visibilidadColumnas = .all
        coordinador.focoDetalle = true
    }

    func enfocarBusqueda() {
        coordinador.busquedaPresentada = true
    }

    func intentarSeleccionar(_ id: UsuarioID?) {
        if hayCambiosEdicion && id != coordinador.seleccion {
            coordinador.pendiente = .seleccionar(id)
            coordinador.alertaDescartar = true
            return
        }
        aplicarSeleccion(id)
    }

    func confirmarDescartar() {
        let pendiente = coordinador.pendiente
        coordinador.alertaDescartar = false
        coordinador.pendiente = .ninguna
        switch pendiente {
        case .ninguna:
            break
        case .seleccionar(let id):
            salirEdicion()
            aplicarSeleccion(id)
        case .verDetalle:
            salirEdicion()
            coordinador.visibilidadColumnas = .all
            coordinador.focoDetalle = true
        case .recargar:
            salirEdicion()
            Task { await cargar(forzarVacio: false) }
        case .cancelarEdicion:
            salirEdicion()
        case .cerrarAlta:
            cerrarAlta()
        case .cerrarSesion, .cambiarSeccion:
            break
        }
    }

    func cancelarDescartar() {
        coordinador.alertaDescartar = false
        coordinador.pendiente = .ninguna
    }

    func guardarActivo() {
        Task {
            if coordinador.mostrandoAlta {
                await guardarAlta()
            } else if coordinador.modoDetalle == .edicion {
                await guardarEdicion()
            }
        }
    }

    func guardarAlta() async {
        revalidarAlta()
        if let primero = InformeValidacion(errores: erroresAlta).primero {
            campoFocoAlta = primero.0
            anunciar(MensajesValidacion.texto(primero.1))
            return
        }
        let alta = UsuarioNuevo(
            nombre: borradorAlta.nombre,
            nombreUsuario: borradorAlta.nombreUsuario,
            correo: borradorAlta.correo
        )
        do {
            let creado = try await crearUsuario.ejecutar(alta)
            insertar(creado)
            cerrarAlta()
            coordinador.seleccion = creado.id
            coordinador.modoDetalle = .lectura
            coordinador.focoDetalle = true
            alCrearUsuario?()
            anunciar(TextosUsuarios.creado)
        } catch let error as ErrorUsuario {
            if case .red(.cancelado) = error { return }
            if case .validacion(let clave) = error {
                aplicarErrorValidacionAlta(clave)
                return
            }
            alertaGuardar = true
        } catch {
            alertaGuardar = true
        }
    }

    func guardarEdicion() async {
        guard let original = usuarioSeleccionado else { return }
        revalidarEdicion()
        if let primero = InformeValidacion(errores: erroresEdicion).primero {
            campoFocoEdicion = primero.0
            anunciar(MensajesValidacion.texto(primero.1))
            return
        }
        let actualizado = original.actualizado(
            nombre: borradorEdicion.nombre,
            nombreUsuario: borradorEdicion.nombreUsuario,
            correo: borradorEdicion.correo
        )
        do {
            let guardado = try await actualizarUsuario.ejecutar(actualizado)
            reemplazar(guardado)
            coordinador.modoDetalle = .lectura
            coordinador.focoDetalle = true
            anunciar(TextosUsuarios.actualizado)
        } catch let error as ErrorUsuario {
            if case .red(.cancelado) = error { return }
            if case .validacion(let clave) = error {
                aplicarErrorValidacionEdicion(clave)
                return
            }
            alertaGuardar = true
        } catch {
            alertaGuardar = true
        }
    }

    func revalidarAlta() {
        validacionEnVivoAlta = true
        erroresAlta = ValidadorUsuario.validar(
            nombre: borradorAlta.nombre,
            nombreUsuario: borradorAlta.nombreUsuario,
            correo: borradorAlta.correo,
            existentes: usuarios,
            excepto: nil
        ).errores
    }

    func revalidarEdicion() {
        validacionEnVivoEdicion = true
        erroresEdicion = ValidadorUsuario.validar(
            nombre: borradorEdicion.nombre,
            nombreUsuario: borradorEdicion.nombreUsuario,
            correo: borradorEdicion.correo,
            existentes: usuarios,
            excepto: coordinador.seleccion
        ).errores
    }

    func consultaCambio() {
        tareaAnuncioBusqueda?.cancel()
        let texto = consulta
        guard !texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        tareaAnuncioBusqueda = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, self.consulta == texto else { return }
                self.anunciar(TextosUsuarios.contador(self.usuariosFiltrados.count))
            }
        }
    }

    func limpiarBusqueda() {
        consulta = ""
    }

    func reintentarCarga() {
        Task { await cargar(forzarVacio: usuarios.isEmpty) }
    }

    private func cargar(forzarVacio: Bool) async {
        cargaGeneracion += 1
        let generacion = cargaGeneracion
        if forzarVacio || usuarios.isEmpty {
            estado = .cargando
            anunciar(TextosUsuarios.cargando)
        } else {
            recargando = true
            anunciar(TextosUsuarios.recargando)
        }
        do {
            let lista = try await listarUsuarios.ejecutar()
            guard generacion == cargaGeneracion else { return }
            usuarios = lista
            estado = .listo
            recargando = false
            bannerRecarga = nil
            if let seleccion = coordinador.seleccion,
               !lista.contains(where: { $0.id == seleccion }) {
                coordinador.seleccion = nil
                coordinador.modoDetalle = .lectura
            }
            anunciar(TextosUsuarios.cargados(lista.count))
        } catch let error as ErrorUsuario {
            guard generacion == cargaGeneracion else { return }
            recargando = false
            if case .red(.cancelado) = error { return }
            if usuarios.isEmpty {
                estado = .error(error)
            } else {
                bannerRecarga = error
            }
            anunciar(MensajesErrorLista.titulo(error))
        } catch {
            guard generacion == cargaGeneracion else { return }
            recargando = false
            if error is CancellationError { return }
            let mapeado = ErrorUsuario.inesperado
            if usuarios.isEmpty {
                estado = .error(mapeado)
            } else {
                bannerRecarga = mapeado
            }
            anunciar(MensajesErrorLista.titulo(mapeado))
        }
    }

    private func aplicarSeleccion(_ id: UsuarioID?) {
        coordinador.seleccion = id
        coordinador.modoDetalle = .lectura
    }

    private func salirEdicion() {
        coordinador.modoDetalle = .lectura
        erroresEdicion = [:]
        validacionEnVivoEdicion = false
        if let usuario = usuarioSeleccionado {
            borradorEdicion = BorradorUsuario(usuario: usuario)
        }
    }

    func descartarEstadoLocal() {
        coordinador.alertaDescartar = false
        coordinador.pendiente = .ninguna
        coordinador.mostrandoAlta = false
        coordinador.modoDetalle = .lectura
        borradorAlta = BorradorUsuario()
        erroresAlta = [:]
        validacionEnVivoAlta = false
        erroresEdicion = [:]
        validacionEnVivoEdicion = false
        if let usuario = usuarioSeleccionado {
            borradorEdicion = BorradorUsuario(usuario: usuario)
        }
    }

    private func cerrarAlta() {
        coordinador.mostrandoAlta = false
        borradorAlta = BorradorUsuario()
        erroresAlta = [:]
        validacionEnVivoAlta = false
    }

    private func insertar(_ usuario: Usuario) {
        if let indice = usuarios.firstIndex(where: { $0.id == usuario.id }) {
            usuarios[indice] = usuario
        } else {
            usuarios.append(usuario)
            usuarios.sort { $0.id.valor < $1.id.valor }
        }
        estado = .listo
    }

    private func reemplazar(_ usuario: Usuario) {
        if let indice = usuarios.firstIndex(where: { $0.id == usuario.id }) {
            usuarios[indice] = usuario
        } else {
            usuarios.append(usuario)
        }
    }

    private func aplicarErrorValidacionAlta(_ clave: String) {
        validacionEnVivoAlta = true
        if let campo = campo(para: clave) {
            erroresAlta[campo] = clave
            campoFocoAlta = campo
        }
        anunciar(MensajesValidacion.texto(clave))
    }

    private func aplicarErrorValidacionEdicion(_ clave: String) {
        validacionEnVivoEdicion = true
        if let campo = campo(para: clave) {
            erroresEdicion[campo] = clave
            campoFocoEdicion = campo
        }
        anunciar(MensajesValidacion.texto(clave))
    }

    private func campo(para clave: String) -> CampoUsuario? {
        switch ClaveValidacionUsuario(rawValue: clave) {
        case .nombreRequerido, .nombreLongitud: return .nombre
        case .nombreUsuarioRequerido, .nombreUsuarioFormato, .nombreUsuarioDuplicado: return .nombreUsuario
        case .correoRequerido, .correoFormato, .correoDuplicado: return .correo
        case nil: return nil
        }
    }

    private func filtrar(_ usuarios: [Usuario], consulta: String) -> [Usuario] {
        let recortada = consulta.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !recortada.isEmpty else { return usuarios }
        let objetivo = Self.normalizar(recortada)
        return usuarios.filter { usuario in
            [usuario.nombre, usuario.nombreUsuario, usuario.correo].contains {
                Self.normalizar($0).contains(objetivo)
            }
        }
    }

    private static func normalizar(_ texto: String) -> String {
        texto.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    private func anunciar(_ mensaje: String) {
        AccessibilityNotification.Announcement(mensaje).post()
    }
}
