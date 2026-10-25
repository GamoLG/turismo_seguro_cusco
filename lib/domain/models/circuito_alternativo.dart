class CircuitoAlternativo {
  final String idCircuito;
  final String nombreCircuito;
  final int tiempoEstimadoMin;
  final double distanciaKm;
  final int porcentajeCongestion;
  final String descripcionCultural;
  final String garantiaSeguridad;

  CircuitoAlternativo({
    required this.idCircuito,
    required this.nombreCircuito,
    required this.tiempoEstimadoMin,
    required this.distanciaKm,
    required this.porcentajeCongestion,
    required this.descripcionCultural,
    required this.garantiaSeguridad,
  });
}