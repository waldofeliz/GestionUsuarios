import SwiftUI

struct InicioVista: View {
    @Bindable var modelo: ShellVistaModelo
    @Environment(\.colorScheme) private var esquema
    @Environment(\.colorSchemeContrast) private var contraste
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TemaUsuarios.espacio20) {
                hero
                kpis
                graficos
                accesos
            }
            .frame(maxWidth: TemaUsuarios.maxAnchoInicio, alignment: .leading)
            .padding(.horizontal, TemaUsuarios.espacio24)
            .padding(.vertical, TemaUsuarios.espacio20)
        }
        .background(TemaUsuarios.ventana)
        .navigationTitle(TextosUsuarios.shellInicio)
    }

    private var estadoKPI: EstadoValorKPI {
        switch modelo.usuarios.estado {
        case .cargando where modelo.usuarios.usuarios.isEmpty:
            return .cargando
        case .error where modelo.usuarios.usuarios.isEmpty:
            return .noDisponible
        default:
            return .numero
        }
    }

    private var resumen: ResumenDashboard {
        modelo.resumen
    }

    private var puntosCiudad: [PuntoGraficoVista] {
        SerieGraficoPresentacion.visibles(resumen.usuariosPorCiudad)
    }

    private var puntosEmpresa: [PuntoGraficoVista] {
        SerieGraficoPresentacion.visibles(resumen.usuariosPorEmpresa)
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: TemaUsuarios.espacio16) {
            AvatarUsuarioVista(
                nombre: modelo.nombreSesion,
                nombreUsuario: modelo.nombreSesion,
                tamano: TemaUsuarios.avatarDetalle
            )
            VStack(alignment: .leading, spacing: TemaUsuarios.espacio4) {
                Text(TextosUsuarios.homeSaludo(modelo.nombreSesion))
                    .font(TemaUsuarios.tipoDisplay)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(IdentificadorAccesibilidad.homeSaludo)
                Text(TextosUsuarios.homeSubtitulo)
                    .font(TemaUsuarios.tipoCuerpo)
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(TemaUsuarios.espacio16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .estiloTarjetaUsuarios(contraste: contraste)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(IdentificadorAccesibilidad.homeHero)
        .accessibilityLabel(TextosUsuarios.homeSaludo(modelo.nombreSesion))
    }

    private var kpis: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: TemaUsuarios.minAnchoKPI), spacing: TemaUsuarios.espacio12)],
            spacing: TemaUsuarios.espacio12
        ) {
            TarjetaKPIInicio(
                label: TextosUsuarios.kpiUsuarios,
                symbol: "person.2",
                relleno: TemaUsuarios.kpiCyan(esquema: esquema, contraste: contraste),
                identificador: IdentificadorAccesibilidad.homeKpiUsuarios,
                estado: estadoKPI,
                valor: resumen.totalUsuarios,
                contraste: contraste
            )
            TarjetaKPIInicio(
                label: TextosUsuarios.kpiCiudades,
                symbol: "map",
                relleno: TemaUsuarios.kpiNaranja(esquema: esquema, contraste: contraste),
                identificador: IdentificadorAccesibilidad.homeKpiCiudades,
                estado: estadoKPI,
                valor: resumen.ciudadesDistintas,
                contraste: contraste
            )
            TarjetaKPIInicio(
                label: TextosUsuarios.kpiEmpresas,
                symbol: "building.2",
                relleno: TemaUsuarios.kpiVerde(esquema: esquema, contraste: contraste),
                identificador: IdentificadorAccesibilidad.homeKpiEmpresas,
                estado: estadoKPI,
                valor: resumen.empresasDistintas,
                contraste: contraste
            )
            TarjetaKPIInicio(
                label: TextosUsuarios.kpiAltas,
                symbol: "person.badge.plus",
                relleno: TemaUsuarios.kpiAzul(esquema: esquema, contraste: contraste),
                identificador: IdentificadorAccesibilidad.homeKpiAltas,
                estado: estadoKPI,
                valor: modelo.altasDeSesion,
                contraste: contraste
            )
        }
    }

    private var graficos: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: TemaUsuarios.espacio20) {
                graficoCiudades
                graficoEmpresas
            }
            VStack(alignment: .leading, spacing: TemaUsuarios.espacio20) {
                graficoCiudades
                graficoEmpresas
            }
        }
    }

    private var graficoCiudades: some View {
        GraficoUsuariosPorCiudadVista(
            puntos: puntosCiudad,
            estado: estadoKPI,
            color: TemaUsuarios.kpiCyan(esquema: esquema, contraste: contraste),
            reduceMotion: reduceMotion
        )
    }

    private var graficoEmpresas: some View {
        GraficoUsuariosPorEmpresaVista(
            puntos: puntosEmpresa,
            estado: estadoKPI,
            color: TemaUsuarios.kpiVerde(esquema: esquema, contraste: contraste),
            reduceMotion: reduceMotion
        )
    }

    private var accesos: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: TemaUsuarios.espacio20) {
                accesoLista
                accesoNuevo
            }
            VStack(alignment: .leading, spacing: TemaUsuarios.espacio20) {
                accesoLista
                accesoNuevo
            }
        }
    }

    private var accesoLista: some View {
        tarjetaAcceso(
            titulo: TextosUsuarios.homeVerListaTitulo,
            cuerpo: TextosUsuarios.homeVerListaCuerpo,
            systemName: "person.crop.rectangle.stack",
            identificador: IdentificadorAccesibilidad.homeVerLista
        ) {
            modelo.irAUsuarios()
        }
    }

    private var accesoNuevo: some View {
        tarjetaAcceso(
            titulo: TextosUsuarios.homeNuevoTitulo,
            cuerpo: TextosUsuarios.homeNuevoCuerpo,
            systemName: "plus",
            identificador: IdentificadorAccesibilidad.homeNuevo
        ) {
            modelo.abrirAltaDesdeInicio()
        }
    }

    private func tarjetaAcceso(
        titulo: String,
        cuerpo: String,
        systemName: String,
        identificador: String,
        accion: @escaping () -> Void
    ) -> some View {
        Button(action: accion) {
            HStack(alignment: .center, spacing: TemaUsuarios.espacio16) {
                SimboloWellUsuarios(systemName: systemName)
                VStack(alignment: .leading, spacing: TemaUsuarios.espacio4) {
                    Text(titulo)
                        .font(TemaUsuarios.tipoTitulo)
                        .foregroundStyle(Color.primary)
                    Text(cuerpo)
                        .font(TemaUsuarios.tipoCuerpo)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.forward")
                    .foregroundStyle(Color.secondary)
                    .accessibilityHidden(true)
            }
            .padding(TemaUsuarios.espacio16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .estiloTarjetaUsuarios(contraste: contraste)
        .accessibilityLabel(titulo)
        .accessibilityHint(cuerpo)
        .accessibilityIdentifier(identificador)
    }
}
