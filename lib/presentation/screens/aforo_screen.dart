import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/models/atractivo_turistico.dart';
import '../../domain/models/circuito_alternativo.dart';
import '../../domain/models/nivel_aforo.dart';
import 'ruta_alterna_screen.dart';

class AforoScreen extends StatefulWidget {
  const AforoScreen({super.key});

  @override
  State<AforoScreen> createState() => _AforoScreenState();
}

class _AforoScreenState extends State<AforoScreen> {
  final MapController _mapController = MapController();
  LatLng _ubicacionUsuario = const LatLng(-13.5164, -71.9772);
  bool _ubicacionObtenida = false;

  final List<AtractivoTuristico> _atractivos = [
    AtractivoTuristico(
      idAtractivo: 'atr_01',
      nombre: 'Piedra de los 12 Ángulos / Hatun Rumiyoc',
      tramo: 'Calle Hatun Rumiyoc (Triunfo - San Blas)',
      coordenadasGps: '-13.5164,-71.9772',
      aforoMaximo: 450,
      aforoActual: 418,
      velocidadTransito: 0.18,
      circuitoAlternativo: CircuitoAlternativo(
        idCircuito: 'circ_01',
        nombreCircuito: 'Circuito Tradicional San Cristóbal y Siete Borreguitos',
        tiempoEstimadoMin: 18,
        distanciaKm: 1.2,
        porcentajeCongestion: 15,
        descripcionCultural: 'Ruta patrimonial alterna que bordea Choquechaka y Saphy, reduciendo el desgaste litico.',
        garantiaSeguridad: 'Patrullaje permanente de la Policía de Turismo (POLTUR)',
      ),
    ),
    AtractivoTuristico(
      idAtractivo: 'atr_02',
      nombre: 'Cuesta de San Blas',
      tramo: 'Acceso Barrio Artesanal',
      coordenadasGps: '-13.5150,-71.9750',
      aforoMaximo: 300,
      aforoActual: 185,
      velocidadTransito: 0.75,
      circuitoAlternativo: null,
    ),
    AtractivoTuristico(
      idAtractivo: 'atr_03',
      nombre: 'Plazoleta San Cristóbal',
      tramo: 'Mirador Panorámico',
      coordenadasGps: '-13.5135,-71.9790',
      aforoMaximo: 500,
      aforoActual: 110,
      velocidadTransito: 1.35,
      circuitoAlternativo: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
  }

  Future<void> _obtenerUbicacionActual() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _ubicacionUsuario = LatLng(pos.latitude, pos.longitude);
          _ubicacionObtenida = true;
        });
      } catch (_) {
        // Mantiene la coordenada por defecto si el sensor tarda
      }
    }
  }

  AtractivoTuristico? _atractivoSeleccionado;

  void _seleccionarAtractivo(AtractivoTuristico atractivo) {
    setState(() {
      _atractivoSeleccionado = atractivo;
    });
    final partes = atractivo.coordenadasGps.split(',');
    final pos = LatLng(double.parse(partes[0]), double.parse(partes[1]));
    _mapController.move(pos, _mapController.camera.zoom);
  }

  void _cerrarDetalle() {
    setState(() {
      _atractivoSeleccionado = null;
    });
  }

  Widget _buildTarjetaCongestion(AtractivoTuristico atractivo) {
    final nivel = atractivo.obtenerEstadoAforo();
    final double ocupacion = atractivo.calcularPorcentajeOcupacion();
    final bool tieneAforoValido = atractivo.aforoMaximo > 0;

    String etiquetaNivel;
    Color colorNivel;
    Color bgNivel;
    Color borderNivel;

    switch (nivel) {
      case NivelAforo.saturado:
        etiquetaNivel = 'Alta';
        colorNivel = const Color(0xFFC62828); // Rojo de alto contraste
        bgNivel = const Color(0xFFFFEBEE);
        borderNivel = const Color(0xFFFFCDD2);
        break;
      case NivelAforo.moderado:
        etiquetaNivel = 'Moderada';
        colorNivel = const Color(0xFFE65100); // Ámbar oscuro
        bgNivel = const Color(0xFFFFF3E0);
        borderNivel = const Color(0xFFFFE0B2);
        break;
      case NivelAforo.optimo:
        etiquetaNivel = 'Baja';
        colorNivel = const Color(0xFF2E7D32); // Verde esmeralda oscuro
        bgNivel = const Color(0xFFE8F5E9);
        borderNivel = const Color(0xFFC8E6C9);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.12),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Encabezado
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            atractivo.nombre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: bgNivel,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderNivel, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: colorNivel,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                etiquetaNivel,
                                style: TextStyle(
                                  color: colorNivel,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.place_outlined, size: 14, color: Colors.blueGrey.shade400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            atractivo.tramo,
                            style: TextStyle(
                              color: Colors.blueGrey.shade600,
                              fontSize: 12.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _cerrarDetalle,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(Icons.close, size: 18, color: Colors.blueGrey.shade400),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // B. Indicador principal (Ocupación única con número destacado y barra de progreso)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Nivel de ocupación',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                tieneAforoValido ? '${ocupacion.toStringAsFixed(1)}%' : 'No disponible',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tieneAforoValido ? colorNivel : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: tieneAforoValido ? (ocupacion / 100.0).clamp(0.0, 1.0) : 0.0,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(colorNivel),
            ),
          ),
          const SizedBox(height: 16),

          // C. Acción principal: «Buscar ruta alternativa»
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (atractivo.circuitoAlternativo != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RutaAlternaScreen(
                        circuito: atractivo.circuitoAlternativo!,
                        origenNombre: atractivo.nombre,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        nivel == NivelAforo.saturado
                            ? 'No hay rutas alternas registradas para este punto.'
                            : 'Zona con tránsito fluido. No se requiere desvío.',
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.alt_route, size: 20),
              label: const Text(
                'Buscar ruta alternativa',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Peatonal en Vivo - Cusco'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-13.5164, -71.9772), // Hatun Rumiyoc
              initialZoom: 16.5,
              onTap: (tapPosition, point) => _cerrarDetalle(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.turismoseguro.cusco',
              ),
              // Círculos semafóricos de congestión
              CircleLayer(
                circles: _atractivos.map((atractivo) {
                  final partes = atractivo.coordenadasGps.split(',');
                  final pos = LatLng(double.parse(partes[0]), double.parse(partes[1]));
                  final esSaturado = atractivo.obtenerEstadoAforo() == NivelAforo.saturado;
                  final esModerado = atractivo.obtenerEstadoAforo() == NivelAforo.moderado;

                  Color color = esSaturado
                      ? Colors.red
                      : (esModerado ? Colors.orange : Colors.green);

                  return CircleMarker(
                    point: pos,
                    radius: esSaturado ? 55 : 35,
                    useRadiusInMeter: true,
                    color: color.withValues(alpha: 0.35),
                    borderColor: color,
                    borderStrokeWidth: 2,
                  );
                }).toList(),
              ),
              // Marcadores de atractivos
              MarkerLayer(
                markers: [
                  // Marcador de posición GPS del usuario
                  if (_ubicacionObtenida)
                    Marker(
                      point: _ubicacionUsuario,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 30),
                    ),
                  ..._atractivos.map((atractivo) {
                    final partes = atractivo.coordenadasGps.split(',');
                    final pos = LatLng(double.parse(partes[0]), double.parse(partes[1]));
                    final esSaturado = atractivo.obtenerEstadoAforo() == NivelAforo.saturado;
                    final esModerado = atractivo.obtenerEstadoAforo() == NivelAforo.moderado;

                    Color color = esSaturado
                        ? Colors.red.shade700
                        : (esModerado ? Colors.orange.shade700 : Colors.green.shade700);

                    return Marker(
                      point: pos,
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _seleccionarAtractivo(atractivo),
                        child: Icon(Icons.location_on, color: color, size: 40),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          if (_atractivoSeleccionado == null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                color: const Color.fromRGBO(255, 255, 255, 0.95),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app, color: Colors.indigo, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Toca un marcador en el mapa para ver la congestión peatonal.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_atractivoSeleccionado != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                top: false,
                child: _buildTarjetaCongestion(_atractivoSeleccionado!),
              ),
            ),
        ],
      ),
    );
  }
}