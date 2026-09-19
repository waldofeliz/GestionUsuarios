import Foundation

nonisolated struct InformeValidacion: Sendable, Equatable {
    var errores: [CampoUsuario: String]

    var esValido: Bool { errores.isEmpty }

    var primero: (CampoUsuario, String)? {
        for campo in CampoUsuario.allCases {
            if let clave = errores[campo] {
                return (campo, clave)
            }
        }
        return nil
    }
}

nonisolated enum ValidadorUsuario {
    private static let patronNombreUsuario = "^[A-Za-z0-9_]{3,20}$"
    private static let patronCorreo = "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"

    static func recortar(_ alta: UsuarioNuevo) -> UsuarioNuevo {
        UsuarioNuevo(
            nombre: alta.nombre.trimmingCharacters(in: .whitespacesAndNewlines),
            nombreUsuario: alta.nombreUsuario.trimmingCharacters(in: .whitespacesAndNewlines),
            correo: alta.correo.trimmingCharacters(in: .whitespacesAndNewlines),
            telefono: alta.telefono,
            sitioWeb: alta.sitioWeb,
            direccion: alta.direccion,
            empresa: alta.empresa
        )
    }

    static func recortar(_ usuario: Usuario) -> Usuario {
        usuario.actualizado(
            nombre: usuario.nombre.trimmingCharacters(in: .whitespacesAndNewlines),
            nombreUsuario: usuario.nombreUsuario.trimmingCharacters(in: .whitespacesAndNewlines),
            correo: usuario.correo.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    static func validar(
        nombre: String,
        nombreUsuario: String,
        correo: String,
        existentes: [Usuario],
        excepto: UsuarioID?
    ) -> InformeValidacion {
        let nombreTrim = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        let usuarioTrim = nombreUsuario.trimmingCharacters(in: .whitespacesAndNewlines)
        let correoTrim = correo.trimmingCharacters(in: .whitespacesAndNewlines)
        var errores: [CampoUsuario: String] = [:]

        if let clave = validarNombre(nombreTrim) {
            errores[.nombre] = clave
        }
        if let clave = validarNombreUsuario(usuarioTrim) {
            errores[.nombreUsuario] = clave
        } else if nombreUsuarioDuplicado(usuarioTrim, en: existentes, excepto: excepto) {
            errores[.nombreUsuario] = ClaveValidacionUsuario.nombreUsuarioDuplicado.rawValue
        }
        if let clave = validarCorreo(correoTrim) {
            errores[.correo] = clave
        } else if correoDuplicado(correoTrim, en: existentes, excepto: excepto) {
            errores[.correo] = ClaveValidacionUsuario.correoDuplicado.rawValue
        }

        return InformeValidacion(errores: errores)
    }

    private static func validarNombre(_ valor: String) -> String? {
        if valor.isEmpty {
            return ClaveValidacionUsuario.nombreRequerido.rawValue
        }
        if valor.count < 2 || valor.count > 80 {
            return ClaveValidacionUsuario.nombreLongitud.rawValue
        }
        return nil
    }

    private static func validarNombreUsuario(_ valor: String) -> String? {
        if valor.isEmpty {
            return ClaveValidacionUsuario.nombreUsuarioRequerido.rawValue
        }
        if !coincide(valor, patron: patronNombreUsuario) {
            return ClaveValidacionUsuario.nombreUsuarioFormato.rawValue
        }
        return nil
    }

    private static func validarCorreo(_ valor: String) -> String? {
        if valor.isEmpty {
            return ClaveValidacionUsuario.correoRequerido.rawValue
        }
        if !coincide(valor, patron: patronCorreo) {
            return ClaveValidacionUsuario.correoFormato.rawValue
        }
        return nil
    }

    private static func nombreUsuarioDuplicado(
        _ valor: String,
        en existentes: [Usuario],
        excepto: UsuarioID?
    ) -> Bool {
        existentes.contains { usuario in
            if usuario.id == excepto { return false }
            return usuario.nombreUsuario.caseInsensitiveCompare(valor) == .orderedSame
        }
    }

    private static func correoDuplicado(
        _ valor: String,
        en existentes: [Usuario],
        excepto: UsuarioID?
    ) -> Bool {
        existentes.contains { usuario in
            if usuario.id == excepto { return false }
            return usuario.correo.caseInsensitiveCompare(valor) == .orderedSame
        }
    }

    private static func coincide(_ valor: String, patron: String) -> Bool {
        valor.range(of: patron, options: .regularExpression) != nil
    }
}
