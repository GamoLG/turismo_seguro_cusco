class CheckpointPeatonal {
  final String numero;
  final String nombre;
  final String detalle;

  const CheckpointPeatonal({
    required this.numero,
    required this.nombre,
    required this.detalle,
  });
}

class PerfilTopografico {
  final String desnivel;
  final String calzada;
  final String advertencia;

  const PerfilTopografico({
    required this.desnivel,
    required this.calzada,
    required this.advertencia,
  });
}

class CircuitoAlternativo {
  final String idCircuito;
  final String nombreCircuito;
  final int tiempoEstimadoMin;
  final double distanciaKm;
  final int porcentajeCongestion;
  final String descripcionCultural;
  final String garantiaSeguridad;
  final List<CheckpointPeatonal> checkpoints;
  final PerfilTopografico? perfilTopografico;

  CircuitoAlternativo({
    required this.idCircuito,
    required this.nombreCircuito,
    required this.tiempoEstimadoMin,
    required this.distanciaKm,
    required this.porcentajeCongestion,
    required this.descripcionCultural,
    required this.garantiaSeguridad,
    this.checkpoints = const [],
    this.perfilTopografico,
  });
}