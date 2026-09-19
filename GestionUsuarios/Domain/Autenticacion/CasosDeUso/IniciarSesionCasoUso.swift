import Foundation

nonisolated protocol IniciarSesionCasoUso: Sendable {
    func ejecutar(_ credenciales: CredencialesInicio) async throws -> Sesion
}

nonisolated struct IniciarSesionServicio: IniciarSesionCasoUso {
    private let verificador: any VerificadorCredenciales
    private let almacen: any AlmacenSesion
    private let intentos: any ControlIntentosAutenticacion
    private let reloj: any RelojAutenticacion

    init(
        verificador: any VerificadorCredenciales,
        almacen: any AlmacenSesion,
        intentos: any ControlIntentosAutenticacion,
        reloj: any RelojAutenticacion = RelojSistema()
    ) {
        self.verificador = verificador
        self.almacen = almacen
        self.intentos = intentos
        self.reloj = reloj
    }

    func ejecutar(_ credenciales: CredencialesInicio) async throws -> Sesion {
        if await almacen.actual() != nil {
            throw ErrorAutenticacion.sesionYaIniciada
        }

        let ahora = await reloj.ahora()
        if let restantes = await intentos.segundosRestantes(ahora: ahora), restantes > 0 {
            throw ErrorAutenticacion.cuentaBloqueada(segundosRestantes: restantes)
        }

        let recortadas = CredencialesInicio(
            nombreUsuario: credenciales.nombreUsuario.trimmingCharacters(in: .whitespacesAndNewlines),
            clave: credenciales.clave
        )

        do {
            try await verificador.verificar(recortadas)
        } catch {
            if let segundos = await intentos.registrarFallo(ahora: ahora) {
                throw ErrorAutenticacion.cuentaBloqueada(segundosRestantes: segundos)
            }
            throw ErrorAutenticacion.credencialesInvalidas
        }

        await intentos.registrarExito()
        let sesion = Sesion(nombreUsuario: recortadas.nombreUsuario, iniciadaEn: ahora)
        await almacen.guardar(sesion)
        return sesion
    }
}
