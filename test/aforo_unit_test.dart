import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:turismo_inteligente_cusco_app/data/services/aforo_sintetico_service.dart';
import 'package:turismo_inteligente_cusco_app/data/services/auth_service.dart';
import 'package:turismo_inteligente_cusco_app/domain/models/atractivo_turistico.dart';
import 'package:turismo_inteligente_cusco_app/domain/models/circuito_alternativo.dart';
import 'package:turismo_inteligente_cusco_app/domain/models/nivel_aforo.dart';
import 'package:turismo_inteligente_cusco_app/domain/models/usuario_model.dart';

void main() {
  group('1. Pruebas Unitarias de Reglas de Negocio de Aforo (AtractivoTuristico)', () {
    test('Calcula el porcentaje de saturación con precisión decimal exacta', () {
      final atractivo = AtractivoTuristico(
        idAtractivo: 'atr_01',
        nombre: 'Hatun Rumiyoc',
        tramo: 'Tramo Triunfo - San Blas',
        coordenadasGps: '-13.5164,-71.9772',
        aforoMaximo: 450,
        aforoActual: 414,
        velocidadTransito: 0.2,
      );
      expect(atractivo.calcularPorcentajeOcupacion(), closeTo(92.0, 0.01));
    });

    test('Retorna 0.0 si el aforo máximo es menor o igual a cero', () {
      final atractivoInvalido = AtractivoTuristico(
        idAtractivo: 'atr_inv',
        nombre: 'Calle Invalida',
        tramo: 'Sin tramo',
        coordenadasGps: '0,0',
        aforoMaximo: 0,
        aforoActual: 50,
        velocidadTransito: 1.0,
      );
      expect(atractivoInvalido.calcularPorcentajeOcupacion(), 0.0);
    });

    test('Retorna 0.0 si el aforo actual es cero', () {
      final vacio = AtractivoTuristico(
        idAtractivo: 'atr_vacio',
        nombre: 'Plazoleta Vacia',
        tramo: 'Mirador',
        coordenadasGps: '-13.5135,-71.9790',
        aforoMaximo: 200,
        aforoActual: 0,
        velocidadTransito: 1.4,
      );
      expect(vacio.calcularPorcentajeOcupacion(), 0.0);
    });

    test('Clasifica como SATURADO cuando la ocupación es mayor o igual al 80%', () {
      final atractivo80 = AtractivoTuristico(
        idAtractivo: 'atr_80',
        nombre: 'Hatun Rumiyoc',
        tramo: 'Tramo Central',
        coordenadasGps: '-13.5164,-71.9772',
        aforoMaximo: 100,
        aforoActual: 80,
        velocidadTransito: 0.3,
      );
      expect(atractivo80.obtenerEstadoAforo(), NivelAforo.saturado);

      final atractivo95 = AtractivoTuristico(
        idAtractivo: 'atr_95',
        nombre: 'Hatun Rumiyoc',
        tramo: 'Tramo Central',
        coordenadasGps: '-13.5164,-71.9772',
        aforoMaximo: 100,
        aforoActual: 95,
        velocidadTransito: 0.15,
      );
      expect(atractivo95.obtenerEstadoAforo(), NivelAforo.saturado);
    });

    test('Clasifica como MODERADO entre 50% y 79.99%', () {
      final moderado50 = AtractivoTuristico(
        idAtractivo: 'atr_mod50',
        nombre: 'Cuesta de San Blas',
        tramo: 'Acceso',
        coordenadasGps: '-13.5150,-71.9750',
        aforoMaximo: 100,
        aforoActual: 50,
        velocidadTransito: 0.8,
      );
      expect(moderado50.obtenerEstadoAforo(), NivelAforo.moderado);

      final moderado79 = AtractivoTuristico(
        idAtractivo: 'atr_mod79',
        nombre: 'Cuesta de San Blas',
        tramo: 'Acceso',
        coordenadasGps: '-13.5150,-71.9750',
        aforoMaximo: 1000,
        aforoActual: 799,
        velocidadTransito: 0.6,
      );
      expect(moderado79.obtenerEstadoAforo(), NivelAforo.moderado);
    });

    test('Clasifica como OPTIMO cuando la ocupación es menor al 50%', () {
      final optimo = AtractivoTuristico(
        idAtractivo: 'atr_opt',
        nombre: 'Plazoleta San Cristóbal',
        tramo: 'Mirador',
        coordenadasGps: '-13.5135,-71.9790',
        aforoMaximo: 100,
        aforoActual: 49,
        velocidadTransito: 1.25,
      );
      expect(optimo.obtenerEstadoAforo(), NivelAforo.optimo);
    });

    test('Sugerir ruta alterna dispara el circuito asignado SOLO en estado de saturación', () {
      final ruta = CircuitoAlternativo(
        idCircuito: 'circ_01',
        nombreCircuito: 'San Cristóbal y Siete Borreguitos',
        tiempoEstimadoMin: 18,
        distanciaKm: 1.2,
        porcentajeCongestion: 15,
        descripcionCultural: 'Ruta alterna patrimonial',
        garantiaSeguridad: 'Patrullaje POLTUR',
      );

      final atractivoSaturado = AtractivoTuristico(
        idAtractivo: 'atr_sat',
        nombre: 'Hatun Rumiyoc',
        tramo: 'Tramo Triunfo - San Blas',
        coordenadasGps: '-13.5164,-71.9772',
        aforoMaximo: 100,
        aforoActual: 90,
        velocidadTransito: 0.2,
        circuitoAlternativo: ruta,
      );
      expect(atractivoSaturado.sugerirRutaAlterna(), isNotNull);
      expect(atractivoSaturado.sugerirRutaAlterna()?.idCircuito, 'circ_01');

      final atractivoModerado = AtractivoTuristico(
        idAtractivo: 'atr_mod',
        nombre: 'Hatun Rumiyoc',
        tramo: 'Tramo Triunfo - San Blas',
        coordenadasGps: '-13.5164,-71.9772',
        aforoMaximo: 100,
        aforoActual: 70,
        velocidadTransito: 0.7,
        circuitoAlternativo: ruta,
      );
      expect(atractivoModerado.sugerirRutaAlterna(), isNull);

      final sinRutaAsignada = AtractivoTuristico(
        idAtractivo: 'atr_sin_ruta',
        nombre: 'Calle Angosta',
        tramo: 'Sector B',
        coordenadasGps: '-13.5164,-71.9772',
        aforoMaximo: 100,
        aforoActual: 95,
        velocidadTransito: 0.2,
        circuitoAlternativo: null,
      );
      expect(sinRutaAsignada.sugerirRutaAlterna(), isNull);
    });
  });

  group('2. Pruebas Unitarias de Modelos de Dominio (Circuito, NivelAforo, Usuario)', () {
    test('CircuitoAlternativo almacena correctamente todos los atributos de navegación', () {
      final circuito = CircuitoAlternativo(
        idCircuito: 'circ_02',
        nombreCircuito: 'Ruta Saphy y Choquechaka',
        tiempoEstimadoMin: 15,
        distanciaKm: 0.95,
        porcentajeCongestion: 12,
        descripcionCultural: 'Conexión histórica con andenería inca',
        garantiaSeguridad: 'Punto de control policial permanente',
      );

      expect(circuito.idCircuito, 'circ_02');
      expect(circuito.nombreCircuito, 'Ruta Saphy y Choquechaka');
      expect(circuito.tiempoEstimadoMin, 15);
      expect(circuito.distanciaKm, 0.95);
      expect(circuito.porcentajeCongestion, 12);
      expect(circuito.descripcionCultural, contains('andenería inca'));
      expect(circuito.garantiaSeguridad, contains('policial'));
    });

    test('NivelAforo enum contiene los tres estados de capacidad requeridos', () {
      expect(NivelAforo.values, containsAll([NivelAforo.optimo, NivelAforo.moderado, NivelAforo.saturado]));
      expect(NivelAforo.values.length, 3);
    });

    test('UsuarioModel serializa correctamente a Map Json y deserializa desde Json', () {
      final fecha = DateTime(2026, 10, 24, 15, 30);
      final usuario = UsuarioModel(
        id: 'usr_123',
        nombreCompleto: 'Diego Ninancuro',
        email: 'diego.ninancuro@unsaac.edu.pe',
        fechaRegistro: fecha,
      );

      final jsonMap = usuario.toJson();
      expect(jsonMap['id'], 'usr_123');
      expect(jsonMap['nombreCompleto'], 'Diego Ninancuro');
      expect(jsonMap['email'], 'diego.ninancuro@unsaac.edu.pe');
      expect(jsonMap['fechaRegistro'], fecha.toIso8601String());

      final usuarioReconstruido = UsuarioModel.fromJson(jsonMap);
      expect(usuarioReconstruido.id, usuario.id);
      expect(usuarioReconstruido.nombreCompleto, usuario.nombreCompleto);
      expect(usuarioReconstruido.email, usuario.email);
      expect(usuarioReconstruido.fechaRegistro, usuario.fechaRegistro);
    });
  });

  group('3. Pruebas Unitarias de Generación Sintética (AforoSinteticoService)', () {
    late AforoSinteticoService servicio;

    setUp(() {
      servicio = AforoSinteticoService(random: Random(42));
    });

    test('Maneja aforoMaximo <= 0 retornando 0', () {
      expect(servicio.generarAforoHorario(0, hora: 11), 0);
      expect(servicio.generarAforoHorario(-10, hora: 11), 0);
    });

    test('Genera aforo crítico (>=80%) en horas punta (10:00 a 13:00 hrs)', () {
      for (int h = 10; h <= 13; h++) {
        final aforo = servicio.generarAforoHorario(100, hora: h);
        expect(aforo, greaterThanOrEqualTo(80), reason: 'Falla en hora punta $h:00');
        expect(aforo, lessThanOrEqualTo(100));
      }
    });

    test('Genera aforo moderado (50% a 79%) en horas intermedias', () {
      final aforoManana = servicio.generarAforoHorario(100, hora: 9);
      expect(aforoManana, greaterThanOrEqualTo(50));
      expect(aforoManana, lessThanOrEqualTo(79));

      final aforoTarde = servicio.generarAforoHorario(100, hora: 15);
      expect(aforoTarde, greaterThanOrEqualTo(50));
      expect(aforoTarde, lessThanOrEqualTo(79));
    });

    test('Genera aforo valle (<50%) en horas tempranas o nocturnas', () {
      final aforoValle = servicio.generarAforoHorario(100, hora: 6);
      expect(aforoValle, lessThanOrEqualTo(49));
    });

    test('Calcula degradación de velocidad peatonal según porcentaje de aforo', () {
      // Saturado >= 80%: velocidad reducida (0.15 a 0.45 m/s)
      final velSaturada = servicio.calcularVelocidadFlujo(95.0);
      expect(velSaturada, lessThanOrEqualTo(0.45));
      expect(velSaturada, greaterThanOrEqualTo(0.15));

      // Moderado 50% - 79%: velocidad media (0.50 a 0.85 m/s)
      final velModerada = servicio.calcularVelocidadFlujo(65.0);
      expect(velModerada, lessThanOrEqualTo(0.85));
      expect(velModerada, greaterThanOrEqualTo(0.50));

      // Óptimo < 50%: velocidad ágil (> 1.10 m/s)
      final velOptima = servicio.calcularVelocidadFlujo(20.0);
      expect(velOptima, greaterThanOrEqualTo(1.10));
    });

    test('cargarDatosMigrados procesa adecuadamente JSON con o sin rutas alternas', () async {
      const mockJson = '''
      [
        {
          "idAtractivo": "test_01",
          "nombre": "Calle Triunfo",
          "tramo": "Plaza Mayor - Hatun Rumiyoc",
          "coordenadasGps": "-13.5160,-71.9770",
          "aforoMaximo": 250,
          "aforoActual": 220,
          "velocidadTransito": 0.25,
          "circuitoAlternativo": {
            "idCircuito": "circ_test",
            "nombreCircuito": "Ruta Santa Catalina",
            "tiempoEstimadoMin": 10,
            "distanciaKm": 0.8,
            "porcentajeCongestion": 10,
            "descripcionCultural": "Paso conventual",
            "garantiaSeguridad": "Camaras C2"
          }
        },
        {
          "idAtractivo": "test_02",
          "nombre": "Calle San Agustin",
          "tramo": "Maruri - Limacpampa",
          "coordenadasGps": "-13.5180,-71.9760",
          "aforoMaximo": 300,
          "aforoActual": 120,
          "velocidadTransito": 1.10,
          "circuitoAlternativo": null
        }
      ]
      ''';

      final lista = await servicio.cargarDatosMigrados(rawJson: mockJson);
      expect(lista.length, 2);
      expect(lista[0].nombre, 'Calle Triunfo');
      expect(lista[0].circuitoAlternativo?.idCircuito, 'circ_test');
      expect(lista[1].nombre, 'Calle San Agustin');
      expect(lista[1].circuitoAlternativo, isNull);
    });

    test('emitirFlujoSensores produce actualizaciones periódicas estocásticas', () async {
      final base = [
        AtractivoTuristico(
          idAtractivo: 'atr_test',
          nombre: 'Test Sensor',
          tramo: 'Tramo 1',
          coordenadasGps: '0,0',
          aforoMaximo: 100,
          aforoActual: 50,
          velocidadTransito: 0.8,
        )
      ];

      final stream = servicio.emitirFlujoSensores(base, intervalo: const Duration(milliseconds: 50));
      final primeraEmision = await stream.first;

      expect(primeraEmision.length, 1);
      expect(primeraEmision[0].idAtractivo, 'atr_test');
      expect(primeraEmision[0].aforoActual, greaterThanOrEqualTo(0));
    });
  });

  group('4. Pruebas Unitarias de Capa de Autenticación (AuthService)', () {
    test('AuthException expone mensaje, código y toString legible', () {
      final excepcion = AuthException('Mensaje de prueba', codigo: 'ERROR_TEST');
      expect(excepcion.mensaje, 'Mensaje de prueba');
      expect(excepcion.codigo, 'ERROR_TEST');
      expect(excepcion.toString(), 'Mensaje de prueba');
    });

    test('AuthService es un Singleton y reporta backend desconectado por diseño de seguridad', () {
      final inst1 = AuthService.instancia;
      final inst2 = AuthService.instancia;
      expect(identical(inst1, inst2), isTrue);
      expect(inst1.tieneBackendConectado, isFalse);
    });

    test('registrarUsuario rechaza simulación ficticia y arroja AuthException controlada', () async {
      expect(
        () async => await AuthService.instancia.registrarUsuario(
          nombreCompleto: 'Diego Shaid',
          email: 'diego@unsaac.edu.pe',
          password: 'passwordSeguro123',
        ),
        throwsA(isA<AuthException>().having((e) => e.codigo, 'codigo', 'BACKEND_NO_CONECTADO')),
      );
    });

    test('iniciarSesion completa su ciclo asíncrono sin lanzar excepciones no controladas', () async {
      await expectLater(
        AuthService.instancia.iniciarSesion(
          email: 'usuario@turismocusco.pe',
          password: 'claveValida',
        ),
        completes,
      );
    });
  });
}
