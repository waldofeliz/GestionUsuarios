import SwiftUI

struct DetalleUsuarioVista: View {
    let usuario: Usuario?

    @Environment(\.colorSchemeContrast) private var contraste

    var body: some View {
        if let usuario {
            ScrollView {
                VStack(alignment: .leading, spacing: TemaUsuarios.espacio20) {
                    hero(usuario)
                    if tieneContacto(usuario) {
                        tarjetaContacto(usuario)
                    }
                    if usuario.direccion != .vacia {
                        tarjetaDireccion(usuario.direccion)
                    }
                    if !estaVacio(usuario.empresa.nombre) {
                        tarjetaEmpresa(usuario.empresa)
                    }
                }
                .padding(.horizontal, TemaUsuarios.espacio24)
                .padding(.vertical, TemaUsuarios.espacio20)
                .frame(maxWidth: TemaUsuarios.maxAnchoFicha, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(TemaUsuarios.ventana)
            .navigationTitle(usuario.nombre)
            .accessibilityAddTraits(.isHeader)
        } else {
            ContentUnavailableView {
                EtiquetaWellUsuarios(
                    titulo: TextosUsuarios.vacioSelTitulo,
                    systemName: "person.crop.rectangle.stack"
                )
            } description: {
                Text(TextosUsuarios.vacioSelCuerpo)
                    .descripcionEmptyUsuarios()
            }
            .accessibilityIdentifier(IdentificadorAccesibilidad.detalleVacio)
        }
    }

    private func hero(_ usuario: Usuario) -> some View {
        HStack(alignment: .center, spacing: TemaUsuarios.espacio16) {
            AvatarUsuarioVista(
                nombre: usuario.nombre,
                nombreUsuario: usuario.nombreUsuario,
                tamano: TemaUsuarios.avatarDetalle
            )
            VStack(alignment: .leading, spacing: TemaUsuarios.espacio4) {
                Text(usuario.nombre)
                    .font(TemaUsuarios.tipoDisplay)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(IdentificadorAccesibilidad.detalleNombre)
                Text("@" + usuario.nombreUsuario)
                    .font(TemaUsuarios.tipoCuerpo)
                    .foregroundStyle(Color.secondary)
                    .accessibilityIdentifier(IdentificadorAccesibilidad.detalleUsername)
                Text(usuario.correo)
                    .font(TemaUsuarios.tipoCuerpo)
                    .foregroundStyle(Color.primary)
                    .textSelection(.enabled)
                    .accessibilityIdentifier(IdentificadorAccesibilidad.detalleEmail)
                Text(TextosUsuarios.badgeId(usuario.id.valor))
                    .font(TemaUsuarios.tipoBadge)
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, TemaUsuarios.espacio8)
                    .padding(.vertical, TemaUsuarios.espacio4)
                    .background(
                        Color.secondary.opacity(0.18),
                        in: RoundedRectangle(cornerRadius: TemaUsuarios.radioBadge)
                    )
                    .accessibilityLabel(TextosUsuarios.badgeIdAccesible(usuario.id.valor))
                    .accessibilityIdentifier(IdentificadorAccesibilidad.detalleId)
            }
        }
        .padding(TemaUsuarios.espacio16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .estiloTarjetaUsuarios(contraste: contraste)
    }

    private func tarjetaContacto(_ usuario: Usuario) -> some View {
        let telefono = recorte(usuario.telefono)
        let sitio = recorte(usuario.sitioWeb)
        return VStack(alignment: .leading, spacing: TemaUsuarios.espacio12) {
            encabezadoSeccion(TextosUsuarios.seccionContacto)
            if !telefono.isEmpty {
                filaTarjeta(
                    symbol: "phone",
                    label: TextosUsuarios.labelTelefono,
                    valor: telefono,
                    identificador: IdentificadorAccesibilidad.detalleTelefono
                )
            }
            if !telefono.isEmpty && !sitio.isEmpty {
                separadorFila()
            }
            if !sitio.isEmpty {
                filaTarjeta(
                    symbol: "link",
                    label: TextosUsuarios.labelSitioWeb,
                    valor: sitio,
                    identificador: IdentificadorAccesibilidad.detalleSitioWeb
                )
            }
        }
        .padding(TemaUsuarios.espacio16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .estiloTarjetaUsuarios(contraste: contraste)
    }

    private func tarjetaDireccion(_ direccion: Direccion) -> some View {
        VStack(alignment: .leading, spacing: TemaUsuarios.espacio12) {
            encabezadoSeccion(TextosUsuarios.seccionDireccion, symbol: "map")
            Text(textoDireccion(direccion))
                .font(TemaUsuarios.tipoCuerpo)
                .foregroundStyle(Color.primary)
                .textSelection(.enabled)
                .accessibilityIdentifier(IdentificadorAccesibilidad.detalleDireccion)
        }
        .padding(TemaUsuarios.espacio16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .estiloTarjetaUsuarios(contraste: contraste)
    }

    private func tarjetaEmpresa(_ empresa: Empresa) -> some View {
        let eslogan = recorte(empresa.eslogan)
        let rubro = recorte(empresa.rubro)
        let tieneDetalle = !eslogan.isEmpty || !rubro.isEmpty
        return VStack(alignment: .leading, spacing: TemaUsuarios.espacio12) {
            encabezadoSeccion(TextosUsuarios.seccionEmpresa, symbol: "building.2")
            if tieneDetalle {
                filaValor(label: TextosUsuarios.labelEmpresa, valor: empresa.nombre)
                if !eslogan.isEmpty {
                    separadorFila()
                    filaValor(label: TextosUsuarios.labelEslogan, valor: eslogan)
                }
                if !rubro.isEmpty {
                    separadorFila()
                    filaValor(label: TextosUsuarios.labelRubro, valor: rubro)
                }
            } else {
                Text(empresa.nombre)
                    .font(TemaUsuarios.tipoCuerpo)
                    .foregroundStyle(Color.primary)
                    .textSelection(.enabled)
            }
        }
        .padding(TemaUsuarios.espacio16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .estiloTarjetaUsuarios(contraste: contraste)
        .accessibilityIdentifier(IdentificadorAccesibilidad.detalleEmpresa)
    }

    private func encabezadoSeccion(_ titulo: String, symbol: String? = nil) -> some View {
        HStack(spacing: TemaUsuarios.espacio8) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: TemaUsuarios.iconoTarjeta))
                    .foregroundStyle(Color.secondary)
                    .accessibilityHidden(true)
            }
            Text(titulo)
                .font(TemaUsuarios.tipoSeccion)
                .foregroundStyle(Color.secondary)
        }
        .accessibilityAddTraits(.isHeader)
    }

    private func filaTarjeta(symbol: String, label: String, valor: String, identificador: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: TemaUsuarios.espacio8) {
            Image(systemName: symbol)
                .font(.system(size: TemaUsuarios.iconoTarjeta))
                .foregroundStyle(Color.secondary)
                .frame(width: TemaUsuarios.iconoTarjeta, height: TemaUsuarios.iconoTarjeta)
                .accessibilityHidden(true)
            filaValor(label: label, valor: valor, identificador: identificador)
        }
    }

    @ViewBuilder
    private func filaValor(label: String, valor: String, identificador: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: TemaUsuarios.espacio2) {
            Text(label)
                .font(TemaUsuarios.tipoLabel)
                .foregroundStyle(Color.secondary)
            if let identificador {
                Text(valor)
                    .font(TemaUsuarios.tipoCuerpo)
                    .foregroundStyle(Color.primary)
                    .textSelection(.enabled)
                    .accessibilityIdentifier(identificador)
            } else {
                Text(valor)
                    .font(TemaUsuarios.tipoCuerpo)
                    .foregroundStyle(Color.primary)
                    .textSelection(.enabled)
            }
        }
    }

    private func separadorFila() -> some View {
        Rectangle()
            .fill(TemaUsuarios.separador)
            .frame(height: 0.5)
            .padding(.leading, TemaUsuarios.insetSeparadorTarjeta)
    }

    private func tieneContacto(_ usuario: Usuario) -> Bool {
        !estaVacio(usuario.telefono) || !estaVacio(usuario.sitioWeb)
    }

    private func estaVacio(_ valor: String) -> Bool {
        recorte(valor).isEmpty
    }

    private func recorte(_ valor: String) -> String {
        valor.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func textoDireccion(_ direccion: Direccion) -> String {
        let calle = recorte(direccion.calle)
        let apartamento = recorte(direccion.apartamento)
        let ciudad = recorte(direccion.ciudad)
        let codigo = recorte(direccion.codigoPostal)
        let linea1 = apartamento.isEmpty ? calle : "\(calle), \(apartamento)"
        let linea2 = [ciudad, codigo].filter { !$0.isEmpty }.joined(separator: "  ")
        if linea2.isEmpty {
            return linea1
        }
        return "\(linea1)\n\(linea2)"
    }
}
