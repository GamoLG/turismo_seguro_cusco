import 'nivel_aforo.dart';
import 'circuito_alternativo.dart';

class AtractivoTuristico {
  final String idAtractivo;
  final String nombre;
  final String tramo;
  final String coordenadasGps;
  final int aforoMaximo;
  int aforoActual;
  double velocidadTransito;
  final CircuitoAlternativo? circuitoAlternativo;

  AtractivoTuristico({
    required this.idAtractivo,
    required this.nombre,
    required this.tramo,
    required this.coordenadasGps,
    required this.aforoMaximo,
    required this.aforoActual,
    required this.velocidadTransito,
    this.circuitoAlternativo,
  });

  double calcularPorcentajeOcupacion() {
    if (aforoMaximo <= 0) return 0.0;
    return (aforoActual / aforoMaximo) * 100.0;
  }

  NivelAforo obtenerEstadoAforo() {
    final double porcentaje = calcularPorcentajeOcupacion();
    if (porcentaje >= 80.0) return NivelAforo.saturado;
    if (porcentaje >= 50.0) return NivelAforo.moderado;
    return NivelAforo.optimo;
  }

  CircuitoAlternativo? sugerirRutaAlterna() {
    if (obtenerEstadoAforo() == NivelAforo.saturado) {
      return circuitoAlternativo;
    }
    return null;
  }
}