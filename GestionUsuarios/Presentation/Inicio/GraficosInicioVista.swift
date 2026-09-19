import Charts
import SwiftUI

struct GraficoUsuariosPorCiudadVista: View {
    let puntos: [PuntoGraficoVista]
    let estado: EstadoValorKPI
    let color: Color
    let reduceMotion: Bool

    var body: some View {
        TarjetaGraficoInicio(
            titulo: TextosUsuarios.chartCiudades,
            identificador: IdentificadorAccesibilidad.homeChartCiudades,
            vacio: TextosUsuarios.chartCiudadesVacio,
            iconoVacio: "map",
            estado: estado,
            hayDatos: !puntos.isEmpty
        ) {
            grafico
        }
    }

    @ViewBuilder
    private var grafico: some View {
        Chart(puntos) { punto in
            AreaMark(
                x: .value(TextosUsuarios.kpiCiudades, punto.indice),
                y: .value(TextosUsuarios.kpiUsuarios, punto.valor)
            )
            .interpolationMethod(.linear)
            .foregroundStyle(color.opacity(0.28))
            LineMark(
                x: .value(TextosUsuarios.kpiCiudades, punto.indice),
                y: .value(TextosUsuarios.kpiUsuarios, punto.valor)
            )
            .interpolationMethod(.linear)
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .chartXScale(domain: 0...max(0, puntos.count - 1))
        .chartYScale(domain: 0...max(1, puntos.map(\.valor).max() ?? 1))
        .chartXAxis {
            AxisMarks(values: puntos.map(\.indice)) { valor in
                AxisGridLine().foregroundStyle(Color.secondary)
                AxisTick().foregroundStyle(Color.primary)
                AxisValueLabel {
                    if let i = valor.as(Int.self), puntos.indices.contains(i) {
                        Text(puntos[i].etiqueta)
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(Color.primary)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(Color.secondary)
                AxisTick().foregroundStyle(Color.primary)
                AxisValueLabel().foregroundStyle(Color.primary)
            }
        }
        .transaction { transaccion in
            if reduceMotion {
                transaccion.animation = nil
            }
        }
        .accessibilityLabel(resumenAccesible)
    }

    private var resumenAccesible: String {
        TextosUsuarios.resumenGrafico(
            prefijo: TextosUsuarios.chartCiudadesA11y,
            puntos: puntos.map { (nombre: $0.etiqueta, valor: $0.valor) }
        )
    }
}

struct GraficoUsuariosPorEmpresaVista: View {
    let puntos: [PuntoGraficoVista]
    let estado: EstadoValorKPI
    let color: Color
    let reduceMotion: Bool

    var body: some View {
        TarjetaGraficoInicio(
            titulo: TextosUsuarios.chartEmpresas,
            identificador: IdentificadorAccesibilidad.homeChartEmpresas,
            vacio: TextosUsuarios.chartEmpresasVacio,
            iconoVacio: "building.2",
            estado: estado,
            hayDatos: !puntos.isEmpty
        ) {
            grafico
        }
    }

    @ViewBuilder
    private var grafico: some View {
        Chart(puntos) { punto in
            BarMark(
                x: .value(TextosUsuarios.kpiUsuarios, punto.valor),
                y: .value(TextosUsuarios.kpiEmpresas, punto.etiqueta)
            )
            .foregroundStyle(color)
        }
        .chartYScale(domain: Array(puntos.map(\.etiqueta).reversed()))
        .chartXScale(domain: 0...max(1, puntos.map(\.valor).max() ?? 1))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(Color.secondary)
                AxisTick().foregroundStyle(Color.primary)
                AxisValueLabel().foregroundStyle(Color.primary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Color.secondary)
                AxisTick().foregroundStyle(Color.primary)
                AxisValueLabel().foregroundStyle(Color.primary)
            }
        }
        .transaction { transaccion in
            if reduceMotion {
                transaccion.animation = nil
            }
        }
        .accessibilityLabel(resumenAccesible)
    }

    private var resumenAccesible: String {
        TextosUsuarios.resumenGrafico(
            prefijo: TextosUsuarios.chartEmpresasA11y,
            puntos: puntos.map { (nombre: $0.etiqueta, valor: $0.valor) }
        )
    }
}

struct TarjetaGraficoInicio<Plot: View>: View {
    @Environment(\.colorSchemeContrast) private var contraste

    let titulo: String
    let identificador: String
    let vacio: String
    let iconoVacio: String
    let estado: EstadoValorKPI
    let hayDatos: Bool
    let plot: Plot

    init(
        titulo: String,
        identificador: String,
        vacio: String,
        iconoVacio: String,
        estado: EstadoValorKPI,
        hayDatos: Bool,
        @ViewBuilder plot: () -> Plot
    ) {
        self.titulo = titulo
        self.identificador = identificador
        self.vacio = vacio
        self.iconoVacio = iconoVacio
        self.estado = estado
        self.hayDatos = hayDatos
        self.plot = plot()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TemaUsuarios.espacio12) {
            Text(titulo)
                .font(TemaUsuarios.tipoTitulo)
                .foregroundStyle(Color.primary)
                .accessibilityAddTraits(.isHeader)
            contenido
                .frame(maxWidth: .infinity, minHeight: TemaUsuarios.altoGrafico, maxHeight: TemaUsuarios.altoGrafico)
        }
        .padding(TemaUsuarios.espacio16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .estiloTarjetaUsuarios(contraste: contraste)
        .accessibilityIdentifier(identificador)
    }

    @ViewBuilder
    private var contenido: some View {
        switch estado {
        case .cargando:
            HStack(spacing: TemaUsuarios.espacio8) {
                ProgressView()
                    .controlSize(.small)
                Text(TextosUsuarios.kpiCarga)
                    .font(TemaUsuarios.tipoCuerpo)
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(TextosUsuarios.kpiCarga)
        case .noDisponible:
            Text(TextosUsuarios.kpiNoDisponible)
                .font(TemaUsuarios.tipoCuerpo)
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        case .numero where !hayDatos:
            VStack(spacing: TemaUsuarios.espacio8) {
                Image(systemName: iconoVacio)
                    .font(.system(size: TemaUsuarios.iconoWell))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
                Text(vacio)
                    .font(TemaUsuarios.tipoCuerpo)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(vacio)
        case .numero:
            plot
        }
    }
}
