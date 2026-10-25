import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../domain/models/atractivo_turistico.dart';
import '../../domain/models/circuito_alternativo.dart';

/// Servicio de simulación y generación de aforo sintético peatonal.
///
/// Modela curvas de afluencia horaria (horas punta y valle) y calcula
/// la degradación de velocidad de marcha peatonal sin requerir llamadas de red.
class AforoSinteticoService {
  final Random _semillaAleatoria;

  AforoSinteticoService({Random? random})
      : _semillaAleatoria = random ?? Random();

  /// Modela aforo según curva horaria determinada:
  /// - Horas punta (10:00 - 13:00): Saturación crítica (80% a 98%).
  /// - Tránsito moderado (08:00 - 09:59 y 14:00 - 17:00): 50% a 79%.
  /// - Hora valle: Tránsito óptimo (10% a 49%).
  int generarAforoHorario(int aforoMaximo, {int? hora}) {
    if (aforoMaximo <= 0) return 0;
    final int h = hora ?? DateTime.now().hour;
    double factor;
    if (h >= 10 && h <= 13) {
      factor = 0.80 + (_semillaAleatoria.nextDouble() * 0.18);
    } else if ((h >= 8 && h < 10) || (h > 13 && h <= 17)) {
      factor = 0.50 + (_semillaAleatoria.nextDouble() * 0.29);
    } else {
      factor = 0.10 + (_semillaAleatoria.nextDouble() * 0.39);
    }
    return (aforoMaximo * factor).round().clamp(0, aforoMaximo);
  }

  /// Calcula la velocidad media de flujo peatonal en m/s en función de la ocupación:
  /// - Saturación (>=80%): Flujo colapsado (~0.15 a 0.45 m/s).
  /// - Moderado (50% a 79%): Flujo denso (~0.50 a 0.85 m/s).
  /// - Óptimo (<50%): Flujo libre peatonal (>1.10 m/s).
  double calcularVelocidadFlujo(double porcentajeOcupacion) {
    if (porcentajeOcupacion >= 80.0) {
      final reduccion = ((porcentajeOcupacion - 80.0) / 20.0) * 0.30;
      final val = (0.45 - reduccion).clamp(0.15, 0.45);
      return double.parse(val.toStringAsFixed(2));
    } else if (porcentajeOcupacion >= 50.0) {
      final val = 0.85 - (((porcentajeOcupacion - 50.0) / 30.0) * 0.35);
      return double.parse(val.clamp(0.50, 0.85).toStringAsFixed(2));
    } else {
      final val = 1.40 - ((porcentajeOcupacion / 50.0) * 0.30);
      return double.parse(val.clamp(1.10, 1.40).toStringAsFixed(2));
    }
  }

  /// Carga datos migrados desde un JSON empaquetado en assets o proporcionado directamente.
  Future<List<AtractivoTuristico>> cargarDatosMigrados({String? rawJson}) async {
    final String contenido = rawJson ?? await rootBundle.loadString('assets/data/atractivos_migrados.json');
    final List<dynamic> decodificado = jsonDecode(contenido) as List<dynamic>;

    return decodificado.map((item) {
      final mapa = item as Map<String, dynamic>;
      CircuitoAlternativo? circuito;
      if (mapa['circuitoAlternativo'] != null) {
        final c = mapa['circuitoAlternativo'] as Map<String, dynamic>;
        circuito = CircuitoAlternativo(
          idCircuito: c['idCircuito'] as String,
          nombreCircuito: c['nombreCircuito'] as String,
          tiempoEstimadoMin: c['tiempoEstimadoMin'] as int,
          distanciaKm: (c['distanciaKm'] as num).toDouble(),
          porcentajeCongestion: c['porcentajeCongestion'] as int,
          descripcionCultural: c['descripcionCultural'] as String,
          garantiaSeguridad: c['garantiaSeguridad'] as String,
        );
      }

      return AtractivoTuristico(
        idAtractivo: mapa['idAtractivo'] as String,
        nombre: mapa['nombre'] as String,
        tramo: mapa['tramo'] as String,
        coordenadasGps: mapa['coordenadasGps'] as String,
        aforoMaximo: mapa['aforoMaximo'] as int,
        aforoActual: mapa['aforoActual'] as int,
        velocidadTransito: (mapa['velocidadTransito'] as num).toDouble(),
        circuitoAlternativo: circuito,
      );
    }).toList();
  }

  /// Emite un flujo de telemetría de sensores periódicos para actualizar el estado reactivo.
  Stream<List<AtractivoTuristico>> emitirFlujoSensores(
    List<AtractivoTuristico> atractivosBase, {
    Duration intervalo = const Duration(seconds: 3),
  }) {
    return Stream.periodic(intervalo, (_) {
      return atractivosBase.map((atractivo) {
        final nuevoAforo = generarAforoHorario(atractivo.aforoMaximo);
        final nuevoPorcentaje = atractivo.aforoMaximo > 0 ? (nuevoAforo / atractivo.aforoMaximo) * 100.0 : 0.0;
        final nuevaVelocidad = calcularVelocidadFlujo(nuevoPorcentaje);
        return AtractivoTuristico(
          idAtractivo: atractivo.idAtractivo,
          nombre: atractivo.nombre,
          tramo: atractivo.tramo,
          coordenadasGps: atractivo.coordenadasGps,
          aforoMaximo: atractivo.aforoMaximo,
          aforoActual: nuevoAforo,
          velocidadTransito: nuevaVelocidad,
          circuitoAlternativo: atractivo.circuitoAlternativo,
        );
      }).toList();
    });
  }
}
