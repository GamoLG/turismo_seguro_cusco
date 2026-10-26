import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/atractivo_turistico.dart';
import '../../domain/models/circuito_alternativo.dart';
import '../../domain/models/nivel_aforo.dart';
import 'ruta_alterna_screen.dart';
import '../../data/services/osrm_routing_service.dart';

enum FiltroAforo { todos, soloCriticos, zonasLibres }

// Modelo para encapsular resultados tanto locales como de OpenStreetMap
class ResultadoBusqueda {
  final String titulo;
  final String subtitulo;
  final LatLng coordenada;
  final AtractivoTuristico? atractivoLocal;
  final bool esExterno;

  ResultadoBusqueda({
    required this.titulo,
    required this.subtitulo,
    required this.coordenada,
    this.atractivoLocal,
    this.esExterno = false,
  });
}

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
  ResultadoBusqueda? _lugarExternoSeleccionado;
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
        descripcionCultural: 'Ruta patrimonial alterna que bordea Choquechaka y Saphy, reduciendo el desgaste lítico en Hatun Rumiyoc.',
        garantiaSeguridad: 'Patrullaje permanente de la Policía de Turismo (POLTUR)',
        perfilTopografico: PerfilTopografico(
          desnivel: '+38 m (Pendiente 6.2%)',
          calzada: 'Empedrado y gradas coloniales',
          advertencia: 'Contiene escalinatas coloniales. Tránsito sugerido a ritmo moderado.',
        ),
        checkpoints: [
          CheckpointPeatonal(numero: '1', nombre: 'Desvío inicial por Calle Choquechaka', detalle: 'Vía lateral ancha con calzada regular (0 - 300 m)'),
          CheckpointPeatonal(numero: '2', nombre: 'Paso por Acueducto Sapantiana', detalle: 'Monumento colonial de desfogue cultural (300 - 750 m)'),
          CheckpointPeatonal(numero: '3', nombre: 'Callejón Siete Borreguitos y Saphy', detalle: 'Corredor empinado hacia miradores (750 - 1050 m)'),
          CheckpointPeatonal(numero: '4', nombre: 'Llegada: Plazoleta San Cristóbal', detalle: 'Zona de aforo libre y descanso panorámico (1.2 km)'),
        ],
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
        descripcionCultural: 'Vía alterna empedrada y tranquila paralela a la Cuesta de San Blas, con menor flujo peatonal.',
        garantiaSeguridad: 'Zona monitoreada con cámaras y serenazgo municipal',
        perfilTopografico: PerfilTopografico(
          desnivel: '+22 m (Pendiente 4.1%)',
          calzada: 'Adoquín colonial y veredas',
          advertencia: 'Vía estrecha en tramos. Evitar en horas de alta concurrencia artesanal.',
        ),
        checkpoints: [
          CheckpointPeatonal(numero: '1', nombre: 'Ingreso por Calle Choquechaka', detalle: 'Desvío desde la base de la Cuesta de San Blas (0 - 200 m)'),
          CheckpointPeatonal(numero: '2', nombre: 'Cruce Plazoleta Succia', detalle: 'Espacio abierto con galerías artesanales (200 - 500 m)'),
          CheckpointPeatonal(numero: '3', nombre: 'Llegada: Plazoleta de las Nazarenas', detalle: 'Zona de aforo reducido y acceso a museos (0.8 km)'),
        ],
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
        descripcionCultural: 'Recorrido cultural por el Palacio Inka Rocha hasta la Plazoleta de las Nazarenas, con menor presión peatonal.',
        garantiaSeguridad: 'Presencia constante de seguridad ciudadana y POLTUR',
        perfilTopografico: PerfilTopografico(
          desnivel: '+15 m (Pendiente 2.8%)',
          calzada: 'Calzada empedrada ancha',
          advertencia: 'Tramo con mayor amplitud. Apto para turistas con movilidad reducida.',
        ),
        checkpoints: [
          CheckpointPeatonal(numero: '1', nombre: 'Desvío desde Calle Triunfo', detalle: 'Giro hacia Palacio Inka Rocha (0 - 150 m)'),
          CheckpointPeatonal(numero: '2', nombre: 'Frente al Palacio Inka Rocha', detalle: 'Hito arquitectónico colonial (150 - 400 m)'),
          CheckpointPeatonal(numero: '3', nombre: 'Llegada: Plazoleta de las Nazarenas', detalle: 'Acceso al Museo Precolombino (0.6 km)'),
        ],
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
        descripcionCultural: 'Vía ancha de salida patrimonial desde Calle Loreto hacia la Avenida El Sol, con bajo nivel de congestión.',
        garantiaSeguridad: 'Patrullaje integrado del centro histórico de Cusco',
        perfilTopografico: PerfilTopografico(
          desnivel: '-10 m (Descenso 2.0%)',
          calzada: 'Calle ancha asfaltada y empedrada',
          advertencia: 'Vía de bajada. Cruce con tráfico vehicular en intersección con Av. El Sol.',
        ),
        checkpoints: [
          CheckpointPeatonal(numero: '1', nombre: 'Salida por Calle Loreto', detalle: 'Desvío hacia Calle Maruri (0 - 150 m)'),
          CheckpointPeatonal(numero: '2', nombre: 'Tramo Maruri - Pampa del Castillo', detalle: 'Corredor amplio de descenso (150 - 400 m)'),
          CheckpointPeatonal(numero: '3', nombre: 'Llegada: Avenida El Sol', detalle: 'Acceso a transporte y zona comercial (0.5 km)'),
        ],
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

  final Map<String, List<Map<String, dynamic>>> _opcionesDesvio = {
    'hatun_rumiyoc': [
      {
        'id': 'desvio_san_cristobal',
        'nombre': 'Vía Choquechaka y San Cristóbal',
        'tiempo': '15 min',
        'distancia': '0.9 km',
        'destino': const LatLng(-13.5132, -71.9804),
        'puntosDirectos': const [
          LatLng(-13.5159, -71.9772),
          LatLng(-13.5154, -71.9765),
          LatLng(-13.5147, -71.9761),
          LatLng(-13.5138, -71.9770),
          LatLng(-13.5134, -71.9782),
          LatLng(-13.5131, -71.9796),
          LatLng(-13.5132, -71.9804),
        ],
      },
      {
        'id': 'desvio_nazarenas',
        'nombre': 'Vía Cuesta Palacio y Nazarenas',
        'tiempo': '7 min',
        'distancia': '0.5 km',
        'destino': const LatLng(-13.5148, -71.9786),
        'puntosDirectos': const [
          LatLng(-13.5159, -71.9772),
          LatLng(-13.5157, -71.9776),
          LatLng(-13.5150, -71.9783),
          LatLng(-13.5148, -71.9786),
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
          LatLng(-13.5151, -71.9763),
          LatLng(-13.5146, -71.9762),
          LatLng(-13.5148, -71.9786),
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
          LatLng(-13.5164, -71.9778),
          LatLng(-13.5155, -71.9790),
          LatLng(-13.5148, -71.9786),
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
          LatLng(-13.5173, -71.9787),
          LatLng(-13.5178, -71.9775),
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
        return _atractivos;
    }
  }

  // BUSCADOR HÍBRIDO (LOCAL + OPENSTREETMAP NOMINATIM CUSCO)
  Future<Iterable<ResultadoBusqueda>> _ejecutarBusqueda(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    List<ResultadoBusqueda> resultados = [];

    // 1. Coincidencias en los atractivos locales (prioridad con semáforo)
    final locales = _atractivos.where((a) =>
    a.nombre.toLowerCase().contains(q) ||
        a.tramo.toLowerCase().contains(q));

    for (var a in locales) {
      final partes = a.coordenadasGps.split(',');
      resultados.add(
        ResultadoBusqueda(
          titulo: a.nombre,
          subtitulo: a.tramo,
          coordenada: LatLng(double.parse(partes[0]), double.parse(partes[1])),
          atractivoLocal: a,
          esExterno: false,
        ),
      );
    }

    // 2. Si el texto tiene al menos 3 caracteres, consulta OpenStreetMap acotado a Cusco
    if (q.length >= 3) {
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?'
              'q=${Uri.encodeComponent(query + ", Cusco")}&format=json&addressdetails=1&limit=4'
              '&viewbox=-72.01,-13.48,-71.93,-13.56&bounded=1',
        );

        final res = await http.get(url, headers: {
          'User-Agent': 'TurismoSeguroCusco/1.0 (contacto@unsaac.edu.pe)',
        }).timeout(const Duration(seconds: 2));

        if (res.statusCode == 200) {
          final List data = json.decode(res.body);
          for (var item in data) {
            final lat = double.tryParse(item['lat'] ?? '');
            final lon = double.tryParse(item['lon'] ?? '');
            if (lat != null && lon != null) {
              final nombre = item['name'] ?? item['display_name'].toString().split(',').first;
              resultados.add(
                ResultadoBusqueda(
                  titulo: nombre,
                  subtitulo: item['display_name'] ?? 'Cusco, Perú',
                  coordenada: LatLng(lat, lon),
                  esExterno: true,
                ),
              );
            }
          }
        }
      } catch (_) {
        // En caso de corte de red, se preservan los resultados locales
      }
    }

    return resultados;
  }

  void _seleccionarAtractivo(AtractivoTuristico atractivo) {
    setState(() {
      _atractivoSeleccionado = atractivo;
      _lugarExternoSeleccionado = null;
      _circuitoSeleccionadoId = null;
      _puntosRutaActiva = [];
      _cargandoRuta = false;
    });
    final partes = atractivo.coordenadasGps.split(',');
    final pos = LatLng(double.parse(partes[0]), double.parse(partes[1]));
    _mapController.move(pos, 16.5);
  }

  void _seleccionarLugarExterno(ResultadoBusqueda lugar) {
    setState(() {
      _lugarExternoSeleccionado = lugar;
      _atractivoSeleccionado = null;
      _circuitoSeleccionadoId = null;
      _puntosRutaActiva = [];
      _cargandoRuta = false;
    });
    _mapController.move(lugar.coordenada, 17.0);
  }

  void _cerrarDetalle() {
    setState(() {
      _atractivoSeleccionado = null;
      _lugarExternoSeleccionado = null;
      _circuitoSeleccionadoId = null;
      _puntosRutaActiva = [];
      _cargandoRuta = false;
    });
  }

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

    if (rutaCalculada.isEmpty || rutaCalculada.length > 80) {
      rutaCalculada = List<LatLng>.from(opcion['puntosDirectos'] as List);
    }

    if (mounted) {
      setState(() {
        _puntosRutaActiva = rutaCalculada;
        _cargandoRuta = false;
      });

      if (_puntosRutaActiva.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(_puntosRutaActiva);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.only(top: 140, bottom: 260, left: 45, right: 45),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Nivel de ocupación',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                  ),
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
            if (esSaturado && tieneOpcionesDesvio) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.alt_route, size: 15, color: Colors.indigo),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Toca una ruta para ver el camino en el mapa:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
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

  // Tarjeta informativa si el usuario buscó un lugar general fuera del monitoreo de aforo
  Widget _buildTarjetaLugarExterno(ResultadoBusqueda lugar) {
    return Container(
      padding: const EdgeInsets.all(14.0),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_city, color: Colors.indigo, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lugar.titulo,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _cerrarDetalle,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.close, size: 18, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            lugar.subtitulo,
            style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 15, color: Colors.blueGrey),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lugar georreferenciado vía OSM. Fuera del área de aforo lítico crítico.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                  ),
                ),
              ],
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
              initialCenter: const LatLng(-13.5159, -71.9772),
              initialZoom: 15.8,
              onTap: (tapPosition, point) => _cerrarDetalle(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.turismoseguro.cusco',
              ),
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
              MarkerLayer(
                markers: [
                  if (_ubicacionObtenida)
                    Marker(
                      point: _ubicacionUsuario,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 28),
                    ),
                  // Marcador de lugar buscado externamente
                  if (_lugarExternoSeleccionado != null)
                    Marker(
                      point: _lugarExternoSeleccionado!.coordenada,
                      width: 45,
                      height: 45,
                      child: const Icon(Icons.location_on, color: Colors.deepPurple, size: 40),
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

          // BARRA DE BÚSQUEDA TIPO GOOGLE MAPS CON OSM NOMINATIM + CHIPS
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.indigo, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Autocomplete<ResultadoBusqueda>(
                            displayStringForOption: (option) => option.titulo,
                            optionsBuilder: (TextEditingValue textEditingValue) async {
                              return await _ejecutarBusqueda(textEditingValue.text);
                            },
                            onSelected: (ResultadoBusqueda seleccion) {
                              FocusScope.of(context).unfocus();
                              if (seleccion.atractivoLocal != null) {
                                _seleccionarAtractivo(seleccion.atractivoLocal!);
                              } else {
                                _seleccionarLugarExterno(seleccion);
                              }
                            },
                            fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                              return TextField(
                                controller: textController,
                                focusNode: focusNode,
                                style: const TextStyle(fontSize: 13.5),
                                decoration: InputDecoration(
                                  hintText: 'Buscar en Cusco (calles, plazas, locales)...',
                                  hintStyle: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              );
                            },
                            
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  color: Colors.white, // El color va en el Material ancestor
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(12),
                                  clipBehavior: Clip.antiAlias, // Asegura que el efecto respete las esquinas redondeadas
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width - 48,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxHeight: 250),
                                      child: ListView.separated(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        separatorBuilder: (_, __) => const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final opcion = options.elementAt(index);
                                          final esLocal = !opcion.esExterno;
                                          final esCritico = esLocal &&
                                              opcion.atractivoLocal!.obtenerEstadoAforo() ==
                                                  NivelAforo.saturado;

                                          return ListTile(
                                            dense: true,
                                            leading: Icon(
                                              esLocal ? Icons.local_activity : Icons.place,
                                              size: 20,
                                              color: esLocal
                                                  ? (esCritico ? Colors.red : Colors.green)
                                                  : Colors.indigo,
                                            ),
                                            title: Text(
                                              opcion.titulo,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Text(
                                              opcion.subtitulo,
                                              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            trailing: esLocal
                                                ? Text(
                                              '${opcion.atractivoLocal!.calcularPorcentajeOcupacion().toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: esCritico ? Colors.red : Colors.green.shade700,
                                              ),
                                            )
                                                : const Icon(Icons.arrow_outward, size: 14, color: Colors.grey),
                                            onTap: () => onSelected(opcion),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_atractivoSeleccionado != null || _lugarExternoSeleccionado != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                            onPressed: _cerrarDetalle,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Todos (10)', style: TextStyle(fontSize: 11.5)),
                        selected: _filtroActual == FiltroAforo.todos,
                        onSelected: (val) => setState(() => _filtroActual = FiltroAforo.todos),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Solo Críticos', style: TextStyle(fontSize: 11.5)),
                        selected: _filtroActual == FiltroAforo.soloCriticos,
                        selectedColor: const Color(0xFFFFCDD2),
                        onSelected: (val) => setState(() => _filtroActual = FiltroAforo.soloCriticos),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Zonas Libres', style: TextStyle(fontSize: 11.5)),
                        selected: _filtroActual == FiltroAforo.zonasLibres,
                        selectedColor: const Color(0xFFC8E6C9),
                        onSelected: (val) => setState(() => _filtroActual = FiltroAforo.zonasLibres),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tarjetas contextuales inferiores
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

          if (_lugarExternoSeleccionado != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                top: false,
                child: _buildTarjetaLugarExterno(_lugarExternoSeleccionado!),
              ),
            ),
        ],
      ),
      floatingActionButton: (_atractivoSeleccionado != null || _lugarExternoSeleccionado != null)
          ? null
          : FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: Colors.indigo,
              onPressed: () => _mapController.move(_ubicacionUsuario, 16.5),
              child: const Icon(Icons.gps_fixed),
            ),
    );
  }
}