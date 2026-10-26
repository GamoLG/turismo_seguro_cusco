import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:turismo_inteligente_cusco_app/data/services/auth_service.dart';
import 'package:turismo_inteligente_cusco_app/data/services/osrm_routing_service.dart';

void main() {
  group('OsrmRoutingService.obtenerRutaPeatonal', () {
    const origen = LatLng(-13.5159, -71.9772);
    const destino = LatLng(-13.5132, -71.9804);

    test('Convierte la geometría GeoJSON en coordenadas LatLng', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'routing.openstreetmap.de');
        expect(request.url.queryParameters['geometries'], 'geojson');
        return http.Response(
          json.encode({
            'routes': [
              {
                'geometry': {
                  'coordinates': [
                    [-71.9772, -13.5159],
                    [-71.9780, -13.5150],
                    [-71.9804, -13.5132],
                  ],
                },
              },
            ],
          }),
          200,
        );
      });

      final ruta = await OsrmRoutingService.obtenerRutaPeatonal(
        origen,
        destino,
        client: client,
      );

      expect(ruta, hasLength(3));
      expect(ruta.first.latitude, -13.5159);
      expect(ruta.first.longitude, -71.9772);
      expect(ruta.last.latitude, -13.5132);
    });

    test('Retorna lista vacía si la respuesta no es 200', () async {
      final client = MockClient((_) async => http.Response('error', 500));

      final ruta = await OsrmRoutingService.obtenerRutaPeatonal(
        origen,
        destino,
        client: client,
      );

      expect(ruta, isEmpty);
    });

    test('Retorna lista vacía si no hay rutas disponibles', () async {
      final client = MockClient(
        (_) async => http.Response(json.encode({'routes': []}), 200),
      );

      final ruta = await OsrmRoutingService.obtenerRutaPeatonal(
        origen,
        destino,
        client: client,
      );

      expect(ruta, isEmpty);
    });

    test('Retorna lista vacía si la geometría no contiene coordenadas', () async {
      final client = MockClient(
        (_) async => http.Response(
          json.encode({
            'routes': [
              {'geometry': <String, dynamic>{}},
            ],
          }),
          200,
        ),
      );

      final ruta = await OsrmRoutingService.obtenerRutaPeatonal(
        origen,
        destino,
        client: client,
      );

      expect(ruta, isEmpty);
    });

    test('Retorna lista vacía ante errores de red o JSON inválido', () async {
      final clienteConError = MockClient((_) async => throw Exception('sin red'));
      final rutaSinRed = await OsrmRoutingService.obtenerRutaPeatonal(
        origen,
        destino,
        client: clienteConError,
      );
      expect(rutaSinRed, isEmpty);

      final clienteJsonInvalido =
          MockClient((_) async => http.Response('no-es-json', 200));
      final rutaInvalida = await OsrmRoutingService.obtenerRutaPeatonal(
        origen,
        destino,
        client: clienteJsonInvalido,
      );
      expect(rutaInvalida, isEmpty);
    });
  });

  group('AuthService', () {
    test('No reporta backend conectado', () {
      expect(AuthService.instancia.tieneBackendConectado, isFalse);
    });

    test('Registro lanza AuthException al no existir backend', () async {
      await expectLater(
        AuthService.instancia.registrarUsuario(
          nombreCompleto: 'Turista de Prueba',
          email: 'turista@unsaac.edu.pe',
          password: 'seguridad2026',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.codigo,
            'codigo',
            'BACKEND_NO_CONECTADO',
          ),
        ),
      );
    });

    test('Inicio de sesión completa su simulación de latencia', () async {
      await expectLater(
        AuthService.instancia.iniciarSesion(
          email: 'turista@unsaac.edu.pe',
          password: 'seguridad2026',
        ),
        completes,
      );
    });

    test('AuthException expone su mensaje en toString', () {
      final excepcion = AuthException('Fallo de autenticación', codigo: 'X');
      expect(excepcion.toString(), 'Fallo de autenticación');
    });
  });
}
