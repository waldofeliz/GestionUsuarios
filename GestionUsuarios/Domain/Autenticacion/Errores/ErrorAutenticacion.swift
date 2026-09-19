import Foundation

nonisolated enum ErrorAutenticacion: Error, Sendable, Equatable {
    case credencialesInvalidas
    case sesionRequerida
    case sesionYaIniciada
    case cuentaBloqueada(segundosRestantes: Int)
}
