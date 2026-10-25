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

  void _mostrarDetalleAforoModal(AtractivoTuristico atractivo) {
    final ocupacion = atractivo.calcularPorcentajeOcupacion();
    final esSaturado = atractivo.obtenerEstadoAforo() == NivelAforo.saturado;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      atractivo.nombre,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: esSaturado ? Colors.red.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      esSaturado ? 'MUCHA CONGESTIÓN' : 'ZONA FLUIDA',
                      style: TextStyle(
                        color: esSaturado ? Colors.red.shade800 : Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(atractivo.tramo, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('${atractivo.aforoActual} / ${atractivo.aforoMaximo}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Aforo Estimado', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('${ocupacion.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Ocupación', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('${atractivo.velocidadTransito.toStringAsFixed(2)} m/s',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Velocidad Marcha', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              if (esSaturado && atractivo.circuitoAlternativo != null) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RutaAlternaScreen(
                            circuito: atractivo.circuitoAlternativo!,
                            origenNombre: atractivo.nombre,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.alt_route),
                    label: const Text(
                      'Ruta alterna: ¿A dónde ir con menos gente?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
            options: const MapOptions(
              initialCenter: LatLng(-13.5164, -71.9772), // Hatun Rumiyoc
              initialZoom: 16.5,
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
                    color: color.withOpacity(0.35),
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
                        onTap: () => _mostrarDetalleAforoModal(atractivo),
                        child: Icon(Icons.location_on, color: color, size: 40),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              color: Colors.white.withOpacity(0.95),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.indigo, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Toca el marcador rojo (12 Ángulos) para ver saturación y solicitar desvío.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}