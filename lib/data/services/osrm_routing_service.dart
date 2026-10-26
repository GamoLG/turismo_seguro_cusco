import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Servicio para calcular rutas peatonales usando el motor OSRM (OpenStreetMap).
class OsrmRoutingService {
  /// Obtiene la lista de coordenadas de la ruta peatonal entre [origen] y [destino].
  /// Si falla o excede el tiempo límite, retorna una lista vacía para activar el fallback directo.
  static Future<List<LatLng>> obtenerRutaPeatonal(
    LatLng origen,
    LatLng destino, {
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      final url = Uri.parse(
        'https://routing.openstreetmap.de/routed-foot/route/v1/foot/'
        '${origen.longitude},${origen.latitude};${destino.longitude},${destino.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await httpClient.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'];
          final coordinates = geometry['coordinates'] as List?;
          if (coordinates != null) {
            return coordinates
                .map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
                .toList();
          }
        }
      }
    } catch (_) {
      // Retorna lista vacía ante cualquier falla de red para usar fallback
    } finally {
      if (client == null) httpClient.close();
    }
    return const [];
  }
}
