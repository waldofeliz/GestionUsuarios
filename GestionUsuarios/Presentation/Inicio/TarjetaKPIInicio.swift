import SwiftUI

struct TarjetaKPIInicio: View {
    let label: String
    let symbol: String
    let relleno: Color
    let identificador: String
    let estado: EstadoValorKPI
    let valor: Int
    let contraste: ColorSchemeContrast

    var body: some View {
        VStack(alignment: .leading, spacing: TemaUsuarios.espacio8) {
            HStack(spacing: TemaUsuarios.espacio8) {
                Image(systemName: symbol)
                    .font(.system(size: 16))
                    .foregroundStyle(TemaUsuarios.kpiTexto)
                    .accessibilityHidden(true)
                Text(label)
                    .font(TemaUsuarios.tipoKPILabel)
                    .foregroundStyle(TemaUsuarios.kpiTexto)
            }
            valorVista
        }
        .padding(TemaUsuarios.espacio16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            relleno,
            in: RoundedRectangle(cornerRadius: TemaUsuarios.radioKPI, style: .continuous)
        )
        .overlay {
            if contraste == .increased {
                RoundedRectangle(cornerRadius: TemaUsuarios.radioKPI, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.45), lineWidth: 1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(labelAccesible)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityIdentifier(identificador)
    }

    @ViewBuilder
    private var valorVista: some View {
        switch estado {
        case .cargando:
            HStack(spacing: TemaUsuarios.espacio8) {
                ProgressView()
                    .controlSize(.small)
                    .tint(TemaUsuarios.kpiTexto)
                Text(TextosUsuarios.kpiCarga)
                    .font(TemaUsuarios.tipoKPIValor)
                    .foregroundStyle(TemaUsuarios.kpiTexto)
            }
        case .noDisponible:
            Text(TextosUsuarios.kpiNoDisponible)
                .font(TemaUsuarios.tipoKPIValor)
                .foregroundStyle(TemaUsuarios.kpiTexto)
        case .numero:
            Text("\(valor)")
                .font(TemaUsuarios.tipoKPIValor)
                .foregroundStyle(TemaUsuarios.kpiTexto)
                .monospacedDigit()
        }
    }

    private var labelAccesible: String {
        switch estado {
        case .cargando:
            return TextosUsuarios.kpiCarga
        case .noDisponible:
            return TextosUsuarios.kpiNoDisponible
        case .numero:
            return TextosUsuarios.kpiAccesible(label: label, valor: valor)
        }
    }
}
