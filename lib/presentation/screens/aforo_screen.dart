import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/models/atractivo_turistico.dart';
import '../../domain/models/circuito_alternativo.dart';
import '../../domain/models/nivel_aforo.dart';
import 'ruta_alterna_screen.dart';
import '../../data/services/osrm_routing_service.dart';

enum FiltroAforo { todos, soloCriticos, zonasLibres }

class AforoScreen extends StatefulWidget {
  const AforoScreen({super.key});

  @override
  State<AforoScreen> createState() => _AforoScreenState();
}

class _AforoScreenState extends State<AforoScreen> {
  final MapController _mapController = MapController();
  LatLng _ubicacionUsuario = const LatLng(-13.5164, -71.9772);
  bool _ubicacionObtenida = false;

  AtractivoTuristico? _atractivoSeleccionado;
  String? _circuitoSeleccionadoId;
  List<LatLng> _puntosRutaActiva = [];
  bool _cargandoRuta = false;
  FiltroAforo _filtroActual = FiltroAforo.todos;

  final List<AtractivoTuristico> _atractivos = [
    AtractivoTuristico(
      idAtractivo: 'hatun_rumiyoc',
      nombre: 'Calle Hatun Rumiyoc (Piedra 12 Ángulos)',
      tramo: 'Calle Hatun Rumiyoc (Triunfo - San Blas)',
      coordenadasGps: '-13.5159,-71.9772',
      aforoMaximo: 200,
      aforoActual: 178,
      velocidadTransito: 0.18,
      circuitoAlternativo: CircuitoAlternativo(
        idCircuito: 'circuito_san_cristobal',
        nombreCircuito: 'Circuito Tradicional San Cristóbal y Siete Borreguitos',
        tiempoEstimadoMin: 18,
        distanciaKm: 1.2,
        porcentajeCongestion: 15,
        descripcionCultural: 'Ruta patrimonial alterna que bordea Choquechaka y Saphy, reduciendo el desgaste lítico.',
        garantiaSeguridad: 'Patrullaje permanente de la Policía de Turismo (POLTUR)',
      ),
    ),
    AtractivoTuristico(
      idAtractivo: 'cuesta_san_blas',
      nombre: 'Cuesta de San Blas',
      tramo: 'Acceso Barrio Artesanal',
      coordenadasGps: '-13.5151,-71.9763',
      aforoMaximo: 160,
      aforoActual: 140,
      velocidadTransito: 0.25,
      circuitoAlternativo: CircuitoAlternativo(
        idCircuito: 'calle_choquechaka',
        nombreCircuito: 'Desvío Choquechaka y Nazarenas',
        tiempoEstimadoMin: 12,
        distanciaKm: 0.8,
        porcentajeCongestion: 20,
        descripcionCultural: 'Vía alterna empedrada y tranquila paralela a la Cuesta de San Blas.',
        garantiaSeguridad: 'Zona monitoreada con cámaras y serenazgo',
      ),
    ),
    AtractivoTuristico(
      idAtractivo: 'calle_triunfo',
      nombre: 'Calle Triunfo',
      tramo: 'Plaza de Armas - Hatun Rumiyoc',
      coordenadasGps: '-13.5164,-71.9778',
      aforoMaximo: 220,
      aforoActual: 195,
      velocidadTransito: 0.20,
      circuitoAlternativo: CircuitoAlternativo(
        idCircuito: 'plazoleta_nazarenas',
        nombreCircuito: 'Corredor Cultural Palacio Inka Rocha - Nazarenas',
        tiempoEstimadoMin: 10,
        distanciaKm: 0.6,
        porcentajeCongestion: 22,
        descripcionCultural: 'Paso por plazoleta monumental y museos coloniales.',
        garantiaSeguridad: 'Presencia constante de seguridad ciudadana',
      ),
    ),
    AtractivoTuristico(
      idAtractivo: 'plaza_san_blas',
      nombre: 'Plazoleta de San Blas',
      tramo: 'Zona de Galerías y Templos',
      coordenadasGps: '-13.5147,-71.9754',
      aforoMaximo: 350,
      aforoActual: 210,
      velocidadTransito: 0.85,
      circuitoAlternativo: null,
    ),
    AtractivoTuristico(
      idAtractivo: 'calle_loreto',
      nombre: 'Calle Loreto (Intikijllu)',
      tramo: 'Acllahuasi - Compañía de Jesús',
      coordenadasGps: '-13.5173,-71.9787',
      aforoMaximo: 180,
      aforoActual: 115,
      velocidadTransito: 0.90,
      circuitoAlternativo: CircuitoAlternativo(
        idCircuito: 'calle_maruri',
        nombreCircuito: 'Desfogue Peatonal Calle Maruri',
        tiempoEstimadoMin: 8,
        distanciaKm: 0.5,
        porcentajeCongestion: 28,
        descripcionCultural: 'Vía ancha de salida patrimonial hacia la Avenida El Sol.',
        garantiaSeguridad: 'Patrullaje integrado centro histórico',
      ),
    ),
    AtractivoTuristico(
      idAtractivo: 'calle_maruri',
      nombre: 'Calle Maruri - Cabildo',
      tramo: 'Av. El Sol - Pampa del Castillo',
      coordenadasGps: '-13.5178,-71.9775',
      aforoMaximo: 450,
      aforoActual: 130,
      velocidadTransito: 1.40,
      circuitoAlternativo: null,
    ),
    AtractivoTuristico(
      idAtractivo: 'calle_choquechaka',
      nombre: 'Calle Choquechaka',
      tramo: 'San Blas - Saphy',
      coordenadasGps: '-13.5142,-71.9760',
      aforoMaximo: 320,
      aforoActual: 75,
      velocidadTransito: 1.30,
      circuitoAlternativo: null,
    ),
    AtractivoTuristico(
      idAtractivo: 'siete_borreguitos',
      nombre: 'Callejón Siete Borreguitos y Sapantiana',
      tramo: 'Pumacurco - Acueducto',
      coordenadasGps: '-13.5135,-71.9780',
      aforoMaximo: 250,
      aforoActual: 50,
      velocidadTransito: 1.25,
      circuitoAlternativo: null,
    ),
    AtractivoTuristico(
      idAtractivo: 'plazoleta_nazarenas',
      nombre: 'Plazoleta de las Nazarenas',
      tramo: 'Museo Precolombino - Palacio Nazarenas',
      coordenadasGps: '-13.5148,-71.9786',
      aforoMaximo: 380,
      aforoActual: 85,
      velocidadTransito: 1.35,
      circuitoAlternativo: null,
    ),
    AtractivoTuristico(
      idAtractivo: 'circuito_san_cristobal',
      nombre: 'Mirador San Cristóbal y Saphy',
      tramo: 'Mirador Panorámico',
      coordenadasGps: '-13.5132,-71.9804',
      aforoMaximo: 500,
      aforoActual: 60,
      velocidadTransito: 1.50,
      circuitoAlternativo: null,
    ),
  ];

  // Catálogo de opciones de desvío con trazados peatonales optimizados directos
  final Map<String, List<Map<String, dynamic>>> _opcionesDesvio = {
    'hatun_rumiyoc': [
      {
        'id': 'desvio_san_cristobal',
        'nombre': 'Vía Choquechaka y San Cristóbal',
        'tiempo': '15 min',
        'distancia': '0.9 km',
        'destino': const LatLng(-13.5132, -71.9804),
        // Camino peatonal directo por esquinas reales (evita rodeos largos)
        'puntosDirectos': const [
          LatLng(-13.5159, -71.9772), // Hatun Rumiyoc
          LatLng(-13.5154, -71.9765), // Salida a Choquechaka
          LatLng(-13.5147, -71.9761), // Recta Choquechaka
          LatLng(-13.5138, -71.9770), // Giro hacia Siete Borreguitos
          LatLng(-13.5134, -71.9782), // Siete Borreguitos
          LatLng(-13.5131, -71.9796), // Arco Iris / Saphy
          LatLng(-13.5132, -71.9804), // Plazoleta San Cristóbal
        ],
      },
      {
        'id': 'desvio_nazarenas',
        'nombre': 'Vía Cuesta Palacio y Nazarenas',
        'tiempo': '7 min',
        'distancia': '0.5 km',
        'destino': const LatLng(-13.5148, -71.9786),
        'puntosDirectos': const [
          LatLng(-13.5159, -71.9772), // Hatun Rumiyoc
          LatLng(-13.5157, -71.9776), // Calle Palacio
          LatLng(-13.5150, -71.9783), // Subida Córdoba del Tucumán
          LatLng(-13.5148, -71.9786), // Plazoleta Nazarenas
        ],
      },
    ],
    'cuesta_san_blas': [
      {
        'id': 'desvio_choquechaka',
        'nombre': 'Desvío Choquechaka - Nazarenas',
        'tiempo': '9 min',
        'distancia': '0.6 km',
        'destino': const LatLng(-13.5148, -71.9786),
        'puntosDirectos': const [
          LatLng(-13.5151, -71.9763), // Cuesta San Blas
          LatLng(-13.5146, -71.9762), // Cruce Choquechaka
          LatLng(-13.5148, -71.9786), // Conector Nazarenas
        ],
      },
    ],
    'calle_triunfo': [
      {
        'id': 'desvio_palacio_nazarenas',
        'nombre': 'Desvío Palacio Inka Rocha - Nazarenas',
        'tiempo': '8 min',
        'distancia': '0.5 km',
        'destino': const LatLng(-13.5148, -71.9786),
        'puntosDirectos': const [
          LatLng(-13.5164, -71.9778), // Triunfo
          LatLng(-13.5155, -71.9790), // Ataúd
          LatLng(-13.5148, -71.9786), // Plazoleta Nazarenas
        ],
      },
    ],
    'calle_loreto': [
      {
        'id': 'desvio_maruri',
        'nombre': 'Desfogue Calle Maruri hacia Av. El Sol',
        'tiempo': '6 min',
        'distancia': '0.4 km',
        'destino': const LatLng(-13.5178, -71.9775),
        'puntosDirectos': const [
          LatLng(-13.5173, -71.9787), // Loreto
          LatLng(-13.5178, -71.9775), // Maruri
        ],
      },
    ],
  };

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
        if (mounted) {
          setState(() {
            _ubicacionUsuario = LatLng(pos.latitude, pos.longitude);
            _ubicacionObtenida = true;
          });
        }
      } catch (_) {}
    }
  }

  List<AtractivoTuristico> get _atractivosFiltrados {
    switch (_filtroActual) {
      case FiltroAforo.soloCriticos:
        return _atractivos.where((a) => a.obtenerEstadoAforo() == NivelAforo.saturado).toList();
      case FiltroAforo.zonasLibres:
        return _atractivos.where((a) => a.obtenerEstadoAforo() == NivelAforo.optimo).toList();
      case FiltroAforo.todos:
      default:
        return _atractivos;
    }
  }

  void _seleccionarAtractivo(AtractivoTuristico atractivo) {
    setState(() {
      _atractivoSeleccionado = atractivo;
      _circuitoSeleccionadoId = null;
      _puntosRutaActiva = [];
      _cargandoRuta = false;
    });
    final partes = atractivo.coordenadasGps.split(',');
    final pos = LatLng(double.parse(partes[0]), double.parse(partes[1]));
    _mapController.move(pos, 16.5);
  }

  void _cerrarDetalle() {
    setState(() {
      _atractivoSeleccionado = null;
      _circuitoSeleccionadoId = null;
      _puntosRutaActiva = [];
      _cargandoRuta = false;
    });
  }

  // SOLO DIBUJA LA RUTA EN EL MAPA (NO ABRE LA OTRA PANTALLA)
  Future<void> _seleccionarRuta(Map<String, dynamic> opcion) async {
    final String id = opcion['id'] as String;

    if (_circuitoSeleccionadoId == id) {
      setState(() {
        _circuitoSeleccionadoId = null;
        _puntosRutaActiva = [];
      });
      return;
    }

    setState(() {
      _circuitoSeleccionadoId = id;
      _cargandoRuta = true;
    });

    final partes = _atractivoSeleccionado!.coordenadasGps.split(',');
    final origen = LatLng(double.parse(partes[0]), double.parse(partes[1]));
    final destino = opcion['destino'] as LatLng;

    List<LatLng> rutaCalculada = await OsrmRoutingService.obtenerRutaPeatonal(origen, destino);

    // Si OSRM no responde o devuelve una ruta con rodeos innecesarios, se usa la ruta peatonal directa
    if (rutaCalculada.isEmpty || rutaCalculada.length > 80) {
      rutaCalculada = List<LatLng>.from(opcion['puntosDirectos'] as List);
    }

    if (mounted) {
      setState(() {
        _puntosRutaActiva = rutaCalculada;
        _cargandoRuta = false;
      });

      // Auto-centra el mapa para mostrar la ruta completa sin salirse de la pantalla
      if (_puntosRutaActiva.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(_puntosRutaActiva);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.only(top: 80, bottom: 260, left: 45, right: 45),
          ),
        );
      }
    }
  }

  Widget _buildTarjetaCongestion(AtractivoTuristico atractivo) {
    final nivel = atractivo.obtenerEstadoAforo();
    final double ocupacion = atractivo.calcularPorcentajeOcupacion();
    final bool tieneAforoValido = atractivo.aforoMaximo > 0;
    final bool esSaturado = nivel == NivelAforo.saturado;
    final bool tieneOpcionesDesvio = _opcionesDesvio.containsKey(atractivo.idAtractivo);

    String etiquetaNivel;
    Color colorNivel;
    Color bgNivel;
    Color borderNivel;

    switch (nivel) {
      case NivelAforo.saturado:
        etiquetaNivel = 'Alta';
        colorNivel = const Color(0xFFC62828);
        bgNivel = const Color(0xFFFFEBEE);
        borderNivel = const Color(0xFFFFCDD2);
        break;
      case NivelAforo.moderado:
        etiquetaNivel = 'Moderada';
        colorNivel = const Color(0xFFE65100);
        bgNivel = const Color(0xFFFFF3E0);
        borderNivel = const Color(0xFFFFE0B2);
        break;
      case NivelAforo.optimo:
        etiquetaNivel = 'Baja';
        colorNivel = const Color(0xFF2E7D32);
        bgNivel = const Color(0xFFE8F5E9);
        borderNivel = const Color(0xFFC8E6C9);
        break;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.44,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.15),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
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
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                const SizedBox(width: 4),
                                Text(
                                  etiquetaNivel,
                                  style: TextStyle(
                                    color: colorNivel,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 13, color: Colors.blueGrey.shade400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              atractivo.tramo,
                              style: TextStyle(
                                color: Colors.blueGrey.shade600,
                                fontSize: 12,
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
            const SizedBox(height: 10),

            // Nivel de Ocupación
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nivel de ocupación',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                ),
                Text(
                  tieneAforoValido ? '${ocupacion.toStringAsFixed(1)}%' : 'N/D',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: tieneAforoValido ? colorNivel : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: tieneAforoValido ? (ocupacion / 100.0).clamp(0.0, 1.0) : 0.0,
                minHeight: 7,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(colorNivel),
              ),
            ),

            // Selector de Rutas de Desvío (Solo visible si está saturado y tiene desvíos asignados)
            if (esSaturado && tieneOpcionesDesvio) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.alt_route, size: 15, color: Colors.indigo),
                  const SizedBox(width: 6),
                  const Text(
                    'Toca una ruta para ver el camino en el mapa:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  if (_cargandoRuta) ...[
                    const Spacer(),
                    const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              ..._opcionesDesvio[atractivo.idAtractivo]!.map((opcion) {
                final bool esSeleccionado = _circuitoSeleccionadoId == opcion['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: InkWell(
                    // Al tocar la opción, solo traza la línea azul en el mapa
                    onTap: () => _seleccionarRuta(opcion),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: esSeleccionado ? const Color(0xFFE8EAF6) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: esSeleccionado ? Colors.indigo : const Color(0xFFE2E8F0),
                          width: esSeleccionado ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            esSeleccionado ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: esSeleccionado ? Colors.indigo : Colors.blueGrey.shade300,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              opcion['nombre'] as String,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: esSeleccionado ? FontWeight.bold : FontWeight.w500,
                                color: esSeleccionado ? Colors.indigo.shade900 : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${opcion['tiempo']} (${opcion['distancia']})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: esSeleccionado ? FontWeight.bold : FontWeight.normal,
                              color: esSeleccionado ? Colors.indigo : Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ] else if (!esSaturado) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Espacio con tránsito fluido. No se requieren desvíos.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF1B5E20), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Botón explícito para ir a la pantalla de detalle
            if (atractivo.circuitoAlternativo != null)
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
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
                  icon: const Icon(Icons.navigation_outlined, size: 16),
                  label: const Text(
                    'Ver detalle del circuito',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
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
              initialCenter: const LatLng(-13.5159, -71.9772), // Hatun Rumiyoc
              initialZoom: 15.8,
              onTap: (tapPosition, point) => _cerrarDetalle(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.turismoseguro.cusco',
              ),

              // Capa de ruta trazada en el mapa
              PolylineLayer(
                polylines: [
                  if (_puntosRutaActiva.isNotEmpty)
                    Polyline(
                      points: _puntosRutaActiva,
                      strokeWidth: 5.0,
                      color: const Color(0xFF1976D2),
                    ),
                ],
              ),

              // Círculos semafóricos con radios no invasivos (22m a 32m)
              CircleLayer(
                circles: _atractivosFiltrados.map((atractivo) {
                  final partes = atractivo.coordenadasGps.split(',');
                  final pos = LatLng(double.parse(partes[0]), double.parse(partes[1]));
                  final esSaturado = atractivo.obtenerEstadoAforo() == NivelAforo.saturado;
                  final esModerado = atractivo.obtenerEstadoAforo() == NivelAforo.moderado;

                  Color color = esSaturado
                      ? Colors.red
                      : (esModerado ? Colors.orange : Colors.green);

                  return CircleMarker(
                    point: pos,
                    radius: esSaturado ? 32 : 22,
                    useRadiusInMeter: true,
                    color: color.withValues(alpha: 0.30),
                    borderColor: color,
                    borderStrokeWidth: 2,
                  );
                }).toList(),
              ),

              // Marcadores de atractivos
              MarkerLayer(
                markers: [
                  if (_ubicacionObtenida)
                    Marker(
                      point: _ubicacionUsuario,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 28),
                    ),
                  ..._atractivosFiltrados.map((atractivo) {
                    final partes = atractivo.coordenadasGps.split(',');
                    final pos = LatLng(double.parse(partes[0]), double.parse(partes[1]));
                    final esSaturado = atractivo.obtenerEstadoAforo() == NivelAforo.saturado;
                    final esModerado = atractivo.obtenerEstadoAforo() == NivelAforo.moderado;

                    Color color = esSaturado
                        ? Colors.red.shade700
                        : (esModerado ? Colors.orange.shade700 : Colors.green.shade700);

                    return Marker(
                      point: pos,
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _seleccionarAtractivo(atractivo),
                        child: Icon(Icons.location_on, color: color, size: 38),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Filtro superior por chips
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todos (10)'),
                    selected: _filtroActual == FiltroAforo.todos,
                    onSelected: (val) => setState(() => _filtroActual = FiltroAforo.todos),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Solo Críticos'),
                    selected: _filtroActual == FiltroAforo.soloCriticos,
                    selectedColor: const Color(0xFFFFCDD2),
                    onSelected: (val) => setState(() => _filtroActual = FiltroAforo.soloCriticos),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Zonas Libres'),
                    selected: _filtroActual == FiltroAforo.zonasLibres,
                    selectedColor: const Color(0xFFC8E6C9),
                    onSelected: (val) => setState(() => _filtroActual = FiltroAforo.zonasLibres),
                  ),
                ],
              ),
            ),
          ),

          // Tarjeta de aforo inferior
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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: _atractivoSeleccionado != null ? 220 : 0),
        child: FloatingActionButton.small(
          backgroundColor: Colors.white,
          foregroundColor: Colors.indigo,
          onPressed: () => _mapController.move(_ubicacionUsuario, 16.5),
          child: const Icon(Icons.gps_fixed),
        ),
      ),
    );
  }
}