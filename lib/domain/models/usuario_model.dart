class UsuarioModel {
  final String id;
  final String nombreCompleto;
  final String email;
  final DateTime fechaRegistro;

  UsuarioModel({
    required this.id,
    required this.nombreCompleto,
    required this.email,
    required this.fechaRegistro,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreCompleto': nombreCompleto,
      'email': email,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as String,
      nombreCompleto: json['nombreCompleto'] as String,
      email: json['email'] as String,
      fechaRegistro: DateTime.parse(json['fechaRegistro'] as String),
    );
  }
}
