import SwiftUI

enum TextosUsuarios {
    static let app = "Gestión de usuarios"
    static let sidebar = "Usuarios"
    static let busqueda = "Buscar usuarios"
    static let vacioSelTitulo = "Selecciona un usuario"
    static let vacioSelCuerpo = "Elige un usuario de la lista para ver su detalle, o crea uno nuevo."
    static let nuevoUsuario = "Nuevo usuario"
    static let editar = "Editar"
    static let actualizarUsuario = "Actualizar usuario"
    static let verDetalle = "Ver detalle"
    static let recargar = "Recargar"
    static let guardar = "Guardar"
    static let cancelar = "Cancelar"
    static let reintentar = "Reintentar"
    static let cerrar = "Cerrar"
    static let limpiarBusqueda = "Limpiar búsqueda"
    static let cargando = "Cargando usuarios…"
    static let recargando = "Recargando usuarios"
    static let vacioTitulo = "No hay usuarios"
    static let vacioCuerpo = "Crea un usuario para empezar. También puedes recargar por si la lista cambió."
    static let sinResultadosTitulo = "Sin resultados"
    static let offlineTitulo = "Sin conexión"
    static let offlineCuerpo = "Comprueba tu red e inténtalo de nuevo."
    static let httpTitulo = "No se pudo cargar"
    static let httpCuerpo = "El servicio no respondió correctamente. Inténtalo de nuevo."
    static let banner = "No se pudo actualizar la lista."
    static let guardarFalloTitulo = "No se pudo guardar"
    static let guardarFalloCuerpo = "El usuario no se registró. Inténtalo de nuevo."
    static let creado = "Usuario creado"
    static let actualizado = "Usuario actualizado"
    static let descartarTitulo = "¿Descartar cambios?"
    static let descartarCuerpo = "Si sales ahora, se perderán los cambios de este usuario."
    static let descartarSi = "Descartar"
    static let descartarNo = "Seguir editando"
    static let labelId = "Identificador"
    static let labelNombre = "Nombre"
    static let labelUsuario = "Nombre de usuario"
    static let labelCorreo = "Correo electrónico"
    static let seccionContacto = "Contacto"
    static let seccionDireccion = "Dirección"
    static let seccionEmpresa = "Empresa"
    static let labelEmpresa = "Empresa"
    static let labelTelefono = "Teléfono"
    static let labelSitioWeb = "Sitio web"
    static let labelEslogan = "Eslogan"
    static let labelRubro = "Rubro"
    static let placeholderNombre = "Ej. Ada Lovelace"
    static let placeholderUsuario = "Ej. ada_lovelace"
    static let placeholderCorreo = "Ej. ada@example.com"
    static let sheetNuevo = "Nuevo usuario"
    static let helpNuevo = "Crear un usuario"
    static let helpRecargar = "Volver a cargar la lista"
    static let helpEditar = "Actualizar los datos del usuario"
    static let buscar = "Buscar"
    static let visualizacion = "Visualización"
    static let valNombreReq = "Escribe un nombre."
    static let valNombreLen = "El nombre debe tener entre 2 y 80 caracteres."
    static let valUsuarioReq = "Escribe un nombre de usuario."
    static let valUsuarioFmt = "Usa 3 a 20 caracteres: letras, números o guion bajo."
    static let valUsuarioDup = "Ese nombre de usuario ya existe."
    static let valCorreoReq = "Escribe un correo electrónico."
    static let valCorreoFmt = "Escribe un correo válido, como nombre@dominio.com."
    static let valCorreoDup = "Ese correo ya está en uso."

    static let loginTitulo = "Iniciar sesión"
    static let loginSubtitulo = "Introduce tu usuario y contraseña."
    static let loginHint = "Usuario de demostración"
    static let loginEntornoDemo = "Entorno de demostración"
    static let loginLabelUsuario = "Usuario"
    static let loginLabelClave = "Contraseña"
    static let loginPlaceholderUsuario = "Ej. tu usuario"
    static let loginEntrar = "Entrar"
    static let loginError = "Usuario o contraseña incorrectos."
    static let valLoginUsuario = "Escribe un usuario."
    static let valLoginClave = "Escribe la contraseña."
    static let loginOk = "Sesión iniciada"
    static let loginClaveOculta = "oculto"
    static let shellInicio = "Inicio"
    static let shellUsuarios = "Usuarios"
    static let homeSubtitulo = "Resumen de tu espacio de trabajo."
    static let homeTotalTitulo = "Usuarios"
    static let homeTotalCarga = "Contando usuarios…"
    static let homeTotalError = "No se pudo obtener el total."
    static let kpiUsuarios = "Usuarios"
    static let kpiCiudades = "Ciudades"
    static let kpiEmpresas = "Empresas"
    static let kpiAltas = "Altas de sesión"
    static let kpiCarga = "Contando…"
    static let kpiNoDisponible = "No disponible"
    static let chartCiudades = "Usuarios por ciudad"
    static let chartEmpresas = "Usuarios por empresa"
    static let chartCiudadesVacio = "No hay ciudades en los usuarios cargados."
    static let chartEmpresasVacio = "No hay empresas en los usuarios cargados."
    static let chartCiudadesA11y = "Usuarios por ciudad."
    static let chartEmpresasA11y = "Usuarios por empresa."
    static let sinCiudad = "Sin ciudad"
    static let sinEmpresa = "Sin empresa"
    static let homeVerListaTitulo = "Ver usuarios"
    static let homeVerListaCuerpo = "Abre la lista para consultar, crear o actualizar."
    static let homeNuevoTitulo = "Nuevo usuario"
    static let homeNuevoCuerpo = "Crea un usuario en un formulario."
    static let cerrarSesion = "Cerrar sesión"
    static let helpCerrarSesion = "Cerrar la sesión y volver al inicio de sesión"
    static let menuCuenta = "Cuenta"
    static let tituloVentanaInicio = "Inicio — Gestión de usuarios"

    static func homeSaludo(_ usuario: String) -> String {
        "Hola, \(usuario)"
    }

    static func loginLockout(_ segundos: Int) -> String {
        "Demasiados intentos. Espera \(segundos) s."
    }

    static func contador(_ n: Int) -> String {
        n == 1 ? "1 usuario" : "\(n) usuarios"
    }

    static func cargados(_ n: Int) -> String {
        n == 1 ? "1 usuario cargado" : "\(n) usuarios cargados"
    }

    static func sinResultadosCuerpo(_ consulta: String) -> String {
        "Ningún usuario coincide con «\(consulta)»."
    }

    static func secundaria(nombreUsuario: String, correo: String) -> String {
        "@\(nombreUsuario) · \(correo)"
    }

    static func tituloEdicion(_ nombre: String) -> String {
        "Editar — \(nombre)"
    }

    static func tituloVentana(nombre: String?) -> String {
        guard let nombre, !nombre.isEmpty else { return app }
        return "\(nombre) — \(app)"
    }

    static func filaAccesible(nombre: String, nombreUsuario: String, correo: String) -> String {
        "\(nombre), \(nombreUsuario), \(correo)"
    }

    static func badgeId(_ n: Int) -> String {
        "ID \(n)"
    }

    static func badgeIdAccesible(_ n: Int) -> String {
        "Identificador, \(n)"
    }

    static func kpiAccesible(label: String, valor: Int) -> String {
        "\(label), \(valor)"
    }

    static func chartOtras(_ k: Int) -> String {
        "Otras (\(k))"
    }

    static func parGrafico(nombre: String, valor: Int) -> String {
        "\(nombre): \(valor)"
    }

    static func resumenGrafico(prefijo: String, puntos: [(nombre: String, valor: Int)]) -> String {
        let pares = puntos.map { parGrafico(nombre: $0.nombre, valor: $0.valor) }
        guard !pares.isEmpty else { return prefijo }
        return prefijo + " " + pares.joined(separator: ", ") + "."
    }

    static func etiquetaAgrupacion(_ clave: ClaveAgrupacion, ausente: String) -> String {
        switch clave {
        case .valor(let texto):
            return texto
        case .ausente:
            return ausente
        }
    }
}

enum IdentificadorAccesibilidad {
    static let listaBusqueda = "lista.busqueda"
    static let listaTitulo = "lista.titulo"
    static let toolbarNuevo = "toolbar.nuevo"
    static let toolbarRecargar = "toolbar.recargar"
    static let toolbarEditar = "toolbar.editar"
    static let detalleVacio = "detalle.vacio"
    static let detalleId = "detalle.id"
    static let detalleNombre = "detalle.nombre"
    static let detalleUsername = "detalle.username"
    static let detalleEmail = "detalle.email"
    static let detalleTelefono = "detalle.telefono"
    static let detalleSitioWeb = "detalle.sitioWeb"
    static let detalleDireccion = "detalle.direccion"
    static let detalleEmpresa = "detalle.empresa"
    static let formNombre = "form.nombre"
    static let formUsername = "form.username"
    static let formEmail = "form.email"
    static let formGuardar = "form.guardar"
    static let formCancelar = "form.cancelar"
    static let estadoCargando = "estado.cargando"
    static let estadoListaVacia = "estado.listaVacia"
    static let estadoBusquedaVacia = "estado.busquedaVacia"
    static let estadoErrorReintentar = "estado.error.reintentar"
    static let estadoErrorBanner = "estado.error.banner"
    static let loginTituloId = "login.titulo"
    static let loginHint = "login.hint"
    static let loginEntornoDemo = "login.entornoDemo"
    static let loginUsuario = "login.usuario"
    static let loginClave = "login.clave"
    static let loginEntrar = "login.entrar"
    static let loginError = "login.error"
    static let loginLockout = "login.lockout"
    static let homeHero = "home.hero"
    static let homeSaludo = "home.saludo"
    static let homeKpiUsuarios = "home.kpi.usuarios"
    static let homeKpiCiudades = "home.kpi.ciudades"
    static let homeKpiEmpresas = "home.kpi.empresas"
    static let homeKpiAltas = "home.kpi.altas"
    static let homeChartCiudades = "home.chart.ciudades"
    static let homeChartEmpresas = "home.chart.empresas"
    static let homeVerLista = "home.verLista"
    static let homeNuevo = "home.nuevo"
    static let shellSidebar = "shell.sidebar"
    static let shellInicio = "shell.inicio"
    static let shellUsuarios = "shell.usuarios"
    static let toolbarLogout = "toolbar.logout"
    static let menuLogout = "menu.logout"

    static func filaUsuario(_ id: UsuarioID) -> String {
        "lista.usuario.\(id.valor)"
    }
}

enum MensajesValidacion {
    static func texto(_ clave: String) -> String {
        switch ClaveValidacionUsuario(rawValue: clave) {
        case .nombreRequerido: return TextosUsuarios.valNombreReq
        case .nombreLongitud: return TextosUsuarios.valNombreLen
        case .nombreUsuarioRequerido: return TextosUsuarios.valUsuarioReq
        case .nombreUsuarioFormato: return TextosUsuarios.valUsuarioFmt
        case .nombreUsuarioDuplicado: return TextosUsuarios.valUsuarioDup
        case .correoRequerido: return TextosUsuarios.valCorreoReq
        case .correoFormato: return TextosUsuarios.valCorreoFmt
        case .correoDuplicado: return TextosUsuarios.valCorreoDup
        case nil: return clave
        }
    }
}

enum MensajesErrorLista {
    static func titulo(_ error: ErrorUsuario) -> String {
        switch error {
        case .red(.sinConexion), .red(.tiempoAgotado):
            return TextosUsuarios.offlineTitulo
        default:
            return TextosUsuarios.httpTitulo
        }
    }

    static func cuerpo(_ error: ErrorUsuario) -> String {
        switch error {
        case .red(.sinConexion), .red(.tiempoAgotado):
            return TextosUsuarios.offlineCuerpo
        default:
            return TextosUsuarios.httpCuerpo
        }
    }
}

struct BorradorUsuario: Equatable {
    var nombre = ""
    var nombreUsuario = ""
    var correo = ""

    var estaVacio: Bool {
        nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && nombreUsuario.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && correo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(nombre: String = "", nombreUsuario: String = "", correo: String = "") {
        self.nombre = nombre
        self.nombreUsuario = nombreUsuario
        self.correo = correo
    }

    init(usuario: Usuario) {
        self.nombre = usuario.nombre
        self.nombreUsuario = usuario.nombreUsuario
        self.correo = usuario.correo
    }

    func coincide(con usuario: Usuario) -> Bool {
        nombre == usuario.nombre && nombreUsuario == usuario.nombreUsuario && correo == usuario.correo
    }
}
