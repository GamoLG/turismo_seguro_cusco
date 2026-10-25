import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turismo_inteligente_cusco_app/domain/models/circuito_alternativo.dart';
import 'package:turismo_inteligente_cusco_app/main.dart';
import 'package:turismo_inteligente_cusco_app/presentation/screens/aforo_screen.dart';
import 'package:turismo_inteligente_cusco_app/presentation/screens/login_screen.dart';
import 'package:turismo_inteligente_cusco_app/presentation/screens/registro_screen.dart';
import 'package:turismo_inteligente_cusco_app/presentation/screens/ruta_alterna_screen.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'checkPermission' || methodCall.method == 'requestPermission') {
          return 0; // LocationPermission.denied
        }
        return 0;
      },
    );
  });

  group('1. Smoke Tests y Pruebas de Renderizado Inicial (TurismoSeguroApp)', () {
    testWidgets('Renderiza MaterialApp y la pantalla inicial de Login correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(const TurismoSeguroApp());

      // Verificación de textos y títulos de cabecera
      expect(find.text('Turismo Seguro Cusco'), findsOneWidget);
      expect(find.text('Monitoreo y Desvío Peatonal Inteligente'), findsOneWidget);

      // Verificación de campos de entrada
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Correo Electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);

      // Verificación de botones de acción
      expect(find.text('Iniciar Sesión'), findsOneWidget);
      expect(find.text('Continuar como Turista Invitado'), findsOneWidget);
      expect(find.text('¿No tienes cuenta?'), findsOneWidget);
      expect(find.text('Regístrate'), findsOneWidget);
    });

    testWidgets('Navegación como Turista Invitado hacia AforoScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const TurismoSeguroApp());

      final botonInvitado = find.text('Continuar como Turista Invitado');
      await tester.tap(botonInvitado);
      await tester.pumpAndSettle();

      expect(find.text('Mapa Peatonal en Vivo - Cusco'), findsOneWidget);
    });
  });

  group('2. Pruebas de Interacción y Validaciones en LoginScreen', () {
    testWidgets('Valida campos obligatorios al intentar iniciar sesión vacíos', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // Presionar Iniciar Sesión sin ingresar credenciales
      final botonIniciar = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');
      await tester.tap(botonIniciar);
      await tester.pump();

      expect(find.text('Ingrese su correo'), findsOneWidget);
      expect(find.text('Ingrese su contraseña'), findsOneWidget);
    });

    testWidgets('Valida formato de correo en LoginScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      final camposTexto = find.byType(TextFormField);
      await tester.enterText(camposTexto.first, 'correo-invalido-sin-arroba');
      await tester.enterText(camposTexto.last, '123456');

      final botonIniciar = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');
      await tester.tap(botonIniciar);
      await tester.pump();

      expect(find.text('Ingrese un correo válido'), findsOneWidget);
    });

    testWidgets('Permite iniciar sesión con credenciales válidas y redirige a AforoScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      final camposTexto = find.byType(TextFormField);
      await tester.enterText(camposTexto.first, 'turista@unsaac.edu.pe');
      await tester.enterText(camposTexto.last, 'passwordValido123');

      final botonIniciar = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');
      await tester.tap(botonIniciar);
      await tester.pumpAndSettle();

      expect(find.text('Mapa Peatonal en Vivo - Cusco'), findsOneWidget);
    });

    testWidgets('Navega hacia RegistroScreen al presionar Regístrate', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      final botonRegistrate = find.text('Regístrate');
      await tester.tap(botonRegistrate);
      await tester.pumpAndSettle();

      expect(find.text('Registro de Usuario'), findsOneWidget);
      expect(find.text('Crear Nueva Cuenta'), findsOneWidget);
    });
  });

  group('3. Pruebas de Interacción y Formularios en RegistroScreen', () {
    testWidgets('Renderiza los campos y encabezado de RegistroScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegistroScreen()));

      expect(find.text('Registro de Usuario'), findsOneWidget);
      expect(find.text('Crear Nueva Cuenta'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.text('Nombre completo'), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Confirmar contraseña'), findsOneWidget);
      expect(find.text('Crear cuenta'), findsOneWidget);
    });

    testWidgets('Valida que las contraseñas coincidan en RegistroScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegistroScreen()));

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'Diego Ninancuro');
      await tester.enterText(campos.at(1), 'diego@unsaac.edu.pe');
      await tester.enterText(campos.at(2), 'password123');
      await tester.enterText(campos.at(3), 'password456');

      final botonCrear = find.text('Crear cuenta');
      await tester.ensureVisible(botonCrear);
      await tester.tap(botonCrear);
      await tester.pump();

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    testWidgets('Valida campos requeridos vacíos en RegistroScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegistroScreen()));

      final botonCrear = find.text('Crear cuenta');
      await tester.ensureVisible(botonCrear);
      await tester.tap(botonCrear);
      await tester.pump();

      expect(find.text('Ingrese su nombre completo'), findsOneWidget);
      expect(find.text('Ingrese su correo electrónico'), findsOneWidget);
      expect(find.text('Ingrese una contraseña'), findsOneWidget);
    });

    testWidgets('Envío con formulario válido muestra diálogo explicativo de backend desconectado', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegistroScreen()));

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'Diego Shaid');
      await tester.enterText(campos.at(1), 'diego.ninancuro@unsaac.edu.pe');
      await tester.enterText(campos.at(2), 'seguridad2026');
      await tester.enterText(campos.at(3), 'seguridad2026');

      final botonCrear = find.text('Crear cuenta');
      await tester.ensureVisible(botonCrear);
      await tester.tap(botonCrear);
      await tester.pump(); // Inicia estado de carga

      // Avanzar temporizador simulado de latencia (800ms)
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(find.text('Autenticación'), findsOneWidget);
      expect(find.text('Entendido'), findsOneWidget);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.text('Autenticación'), findsNothing);
    });
  });

  group('4. Pruebas de Renderizado e Interacción en AforoScreen', () {
    testWidgets('Renderiza mapa peatonal, marcadores y card informativa', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AforoScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Mapa Peatonal en Vivo - Cusco'), findsOneWidget);
      expect(find.text('Toca un marcador en el mapa para ver la congestión peatonal.'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsWidgets);
    });

    testWidgets('Selecciona un atractivo y muestra tarjeta de saturación con botón de desvío', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AforoScreen()));
      await tester.pumpAndSettle();

      // Tocar el primer marcador en el mapa
      final primerMarcador = find.byIcon(Icons.location_on).first;
      await tester.tap(primerMarcador);
      await tester.pumpAndSettle();

      // Debe aparecer la tarjeta de congestión y el botón de ruta alterna
      expect(find.text('Nivel de ocupación'), findsOneWidget);
      expect(find.text('Buscar ruta alternativa'), findsOneWidget);

      // Presionar buscar ruta alternativa
      await tester.tap(find.text('Buscar ruta alternativa'));
      await tester.pumpAndSettle();

      // Debe navegar hacia RutaAlternaScreen
      expect(find.text('Desvío Peatonal Sugerido'), findsOneWidget);
    });

    testWidgets('Permite cerrar el detalle de congestión al presionar icono de cerrar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AforoScreen()));
      await tester.pumpAndSettle();

      final primerMarcador = find.byIcon(Icons.location_on).first;
      await tester.tap(primerMarcador);
      await tester.pumpAndSettle();

      expect(find.text('Nivel de ocupación'), findsOneWidget);

      final botonCerrar = find.byIcon(Icons.close);
      await tester.tap(botonCerrar);
      await tester.pumpAndSettle();

      expect(find.text('Nivel de ocupación'), findsNothing);
    });
  });

  group('5. Pruebas de Renderizado de RutaAlternaScreen', () {
    testWidgets('Muestra correctamente métricas de distancia, tiempo y garantía POLTUR', (WidgetTester tester) async {
      final circuito = CircuitoAlternativo(
        idCircuito: 'circ_01',
        nombreCircuito: 'Circuito Tradicional San Cristóbal y Siete Borreguitos',
        tiempoEstimadoMin: 18,
        distanciaKm: 1.2,
        porcentajeCongestion: 15,
        descripcionCultural: 'Ruta patrimonial alterna que bordea Choquechaka y Saphy.',
        garantiaSeguridad: 'Patrullaje permanente de la Policía de Turismo (POLTUR)',
      );

      await tester.pumpWidget(MaterialApp(
        home: RutaAlternaScreen(
          circuito: circuito,
          origenNombre: 'Calle Hatun Rumiyoc',
        ),
      ));

      expect(find.text('Desvío Peatonal Sugerido'), findsOneWidget);
      expect(find.text(circuito.nombreCircuito), findsOneWidget);
      expect(find.text('1.2 km'), findsOneWidget);
      expect(find.text('18 min'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);
      expect(find.text('Seguridad Garantizada'), findsOneWidget);
      expect(find.text(circuito.garantiaSeguridad), findsOneWidget);
      expect(find.text('Iniciar Navegación Asistida'), findsOneWidget);
    });

    testWidgets('Permite alternar inicio y parada de navegación en RutaAlternaScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final circuito = CircuitoAlternativo(
        idCircuito: 'circ_01',
        nombreCircuito: 'Circuito Tradicional San Cristóbal',
        tiempoEstimadoMin: 18,
        distanciaKm: 1.2,
        porcentajeCongestion: 15,
        descripcionCultural: 'Ruta patrimonial alterna.',
        garantiaSeguridad: 'Patrullaje permanente POLTUR',
      );

      await tester.pumpWidget(MaterialApp(
        home: RutaAlternaScreen(
          circuito: circuito,
          origenNombre: 'Hatun Rumiyoc',
        ),
      ));

      final botonNavegar = find.text('Iniciar Navegación Asistida');
      await tester.ensureVisible(botonNavegar);
      await tester.tap(botonNavegar);
      await tester.pump();

      expect(find.text('Navegación iniciada. Conteo de pasos y GPS activo.'), findsOneWidget);
      expect(find.text('Detener Navegación'), findsOneWidget);

      await tester.tap(find.text('Detener Navegación'));
      await tester.pump();
      expect(find.text('Iniciar Navegación Asistida'), findsOneWidget);
    });
  });
}
