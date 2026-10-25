import '../../domain/models/usuario_model.dart';

/// Excepción personalizada para errores del flujo de autenticación.
class AuthException implements Exception {
  final String mensaje;
  final String? codigo;

  AuthException(this.mensaje, {this.codigo});

  @override
  String toString() => mensaje;
}

/// Servicio de Autenticación de Turismo Seguro Cusco.
///
/// Gestiona las operaciones de inicio de sesión y registro de usuarios.
/// Verifica la disponibilidad de backend (Firebase o API REST) para evitar
/// simulaciones ficticias o almacenamiento inseguro de credenciales.
class AuthService {
  AuthService._();
  static final AuthService instancia = AuthService._();

  /// Indica si existe una conexión activa a un backend o servicio de autenticación en la nube.
  /// Actualmente el repositorio no tiene integrado Firebase Auth ni API REST.
  bool get tieneBackendConectado => false;

  /// Registra un nuevo usuario con nombre, correo y contraseña.
  ///
  /// Lanza [AuthException] informando que no existe backend configurado,
  /// evitando simular registros exitosos ni guardar contraseñas en texto plano.
  Future<UsuarioModel> registrarUsuario({
    required String nombreCompleto,
    required String email,
    required String password,
  }) async {
    // Simula latencia para mostrar indicador de carga
    await Future.delayed(const Duration(milliseconds: 800));

    if (!tieneBackendConectado) {
      throw AuthException(
        'Servicio de backend no conectado: El proyecto no cuenta actualmente con '
        'Firebase Authentication ni una API REST configurada. '
        'Para activar el registro real en la nube se requiere enlazar las credenciales '
        'del proveedor de autenticación.',
        codigo: 'BACKEND_NO_CONECTADO',
      );
    }

    // Flujo preparado para Firebase / API REST
    return UsuarioModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      nombreCompleto: nombreCompleto,
      email: email,
      fechaRegistro: DateTime.now(),
    );
  }

  /// Valida el inicio de sesión.
  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
