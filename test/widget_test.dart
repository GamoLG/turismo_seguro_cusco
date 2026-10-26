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
      expect(find.text('Todos (10)'), findsOneWidget);
      expect(find.text('Solo Críticos'), findsOneWidget);
      expect(find.text('Zonas Libres'), findsOneWidget);
      expect(find.text('Buscar en Cusco (calles, plazas, locales)...'), findsOneWidget);
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

      // Debe aparecer la tarjeta de congestión y el botón de detalle
      expect(find.text('Nivel de ocupación'), findsOneWidget);
      expect(find.text('Ver detalle del circuito'), findsOneWidget);

      // Presionar ver detalle del circuito
      await tester.tap(find.text('Ver detalle del circuito'));
      await tester.pumpAndSettle();

      // Debe navegar hacia RutaAlternaScreen
      expect(find.text('Desvío Recomendado'), findsOneWidget);
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

    testWidgets('Filtros de aforo actualizan los marcadores del mapa', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AforoScreen()));
      await tester.pumpAndSettle();

      final marcadoresTodos = find.byIcon(Icons.location_on).evaluate().length;

      await tester.tap(find.text('Solo Críticos'));
      await tester.pumpAndSettle();
      final marcadoresCriticos = find.byIcon(Icons.location_on).evaluate().length;

      await tester.tap(find.text('Zonas Libres'));
      await tester.pumpAndSettle();
      final marcadoresLibres = find.byIcon(Icons.location_on).evaluate().length;

      expect(marcadoresCriticos, lessThan(marcadoresTodos));
      expect(marcadoresLibres, lessThan(marcadoresTodos));
      expect(marcadoresLibres, greaterThan(0));

      await tester.tap(find.text('Todos (10)'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.location_on).evaluate().length, marcadoresTodos);
    });

    testWidgets('La búsqueda local encuentra atractivos y permite seleccionarlos', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AforoScreen()));
      await tester.pumpAndSettle();

      final campo = find.byType(TextField).first;
      await tester.enterText(campo, 'Hatun');
      await tester.pumpAndSettle();

      expect(find.text('Calle Hatun Rumiyoc (Piedra 12 Ángulos)'), findsWidgets);

      await tester.tap(find.text('Calle Hatun Rumiyoc (Piedra 12 Ángulos)').last);
      await tester.pumpAndSettle();

      expect(find.text('Nivel de ocupación'), findsOneWidget);
    });

    testWidgets('Selecciona y deselecciona una ruta de desvío saturada', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AforoScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.location_on).first);
      await tester.pumpAndSettle();

      final opcion = find.text('Vía Choquechaka y San Cristóbal');
      expect(opcion, findsOneWidget);

      await tester.tap(opcion);
      await tester.pumpAndSettle();
      expect(find.text('Vía Choquechaka y San Cristóbal'), findsOneWidget);

      await tester.tap(opcion);
      await tester.pumpAndSettle();
      expect(find.text('Nivel de ocupación'), findsOneWidget);
    });

    testWidgets('Muestra la ubicación del usuario cuando el permiso es concedido', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const canal = MethodChannel('flutter.baseflow.com/geolocator');
      messenger.setMockMethodCallHandler(canal, (MethodCall call) async {
        switch (call.method) {
          case 'checkPermission':
          case 'requestPermission':
            return 2; // LocationPermission.whileInUse
          case 'getCurrentPosition':
            return <String, dynamic>{
              'latitude': -13.5159,
              'longitude': -71.9772,
              'accuracy': 5.0,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            };
          default:
            return 0;
        }
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(canal, (MethodCall call) async => 0);
      });

      await tester.pumpWidget(const MaterialApp(home: AforoScreen()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.my_location), findsOneWidget);
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

      expect(find.text('Desvío Recomendado'), findsOneWidget);
      expect(find.text(circuito.nombreCircuito), findsOneWidget);
      expect(find.text('1.2 km'), findsOneWidget);
      expect(find.text('18 min'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);
      expect(find.text(circuito.garantiaSeguridad), findsOneWidget);
      expect(find.text('Iniciar Navegación'), findsOneWidget);
      // Sin checkpoints ni perfil topográfico no se muestran esas secciones
      expect(find.textContaining('Itinerario'), findsNothing);
      expect(find.byIcon(Icons.terrain), findsNothing);
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

      await tester.tap(find.text('Iniciar Navegación'));
      await tester.pump();

      expect(find.text('Navegación asistida activa. Monitoreo por cuadrantes POLTUR iniciado.'), findsOneWidget);
      expect(find.text('Finalizar Navegación'), findsOneWidget);

      await tester.tap(find.text('Finalizar Navegación'));
      await tester.pump();
      expect(find.text('Iniciar Navegación'), findsOneWidget);
    });

    testWidgets('Muestra perfil topográfico e itinerario desplegable', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final circuito = CircuitoAlternativo(
        idCircuito: 'circ_02',
        nombreCircuito: 'Circuito San Blas',
        tiempoEstimadoMin: 12,
        distanciaKm: 0.8,
        porcentajeCongestion: 20,
        descripcionCultural: 'Vía alterna empedrada.',
        garantiaSeguridad: 'Zona monitoreada con cámaras',
        perfilTopografico: const PerfilTopografico(
          desnivel: '+22 m (Pendiente 4.1%)',
          calzada: 'Adoquín colonial',
          advertencia: 'Vía estrecha en tramos.',
        ),
        checkpoints: const [
          CheckpointPeatonal(numero: '1', nombre: 'Ingreso por Choquechaka', detalle: 'Tramo inicial'),
          CheckpointPeatonal(numero: '2', nombre: 'Llegada a Nazarenas', detalle: 'Tramo final'),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: RutaAlternaScreen(
          circuito: circuito,
          origenNombre: 'Cuesta de San Blas',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('+22 m'), findsOneWidget);
      expect(find.text('Vía estrecha en tramos.'), findsOneWidget);
      expect(find.text('Itinerario · 2 paradas'), findsOneWidget);
      expect(find.text('Ingreso por Choquechaka'), findsNothing);

      await tester.scrollUntilVisible(find.text('Itinerario · 2 paradas'), 120);
      await tester.tap(find.text('Itinerario · 2 paradas'));
      await tester.pumpAndSettle();

      expect(find.text('Ingreso por Choquechaka'), findsOneWidget);
      expect(find.text('Llegada a Nazarenas'), findsOneWidget);
    });
    testWidgets('Presionar el icono de cerrar sesión en AforoScreen navega hacia el Login', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AforoScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Busca el botón de cerrar sesión en el AppBar
      final botonLogout = find.byTooltip('Cerrar sesión');
      expect(botonLogout, findsOneWidget);

      // Presiona el botón de logout
      await tester.tap(botonLogout);
      await tester.pumpAndSettle();

      // Verifica que AforoScreen ya no esté y se haya montado la nueva ruta
      expect(find.byType(AforoScreen), findsNothing);
    });
  });
}
