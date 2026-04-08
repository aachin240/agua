class UsuarioSesion {
  final int idUsuario;
  final String nombre;
  final String username;

  const UsuarioSesion({
    required this.idUsuario,
    required this.nombre,
    required this.username,
  });

  factory UsuarioSesion.fromJson(Map<String, dynamic> json) {
    return UsuarioSesion(
      idUsuario: int.parse(json['id_usuario'].toString()),
      nombre: (json['nombre'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'nombre': nombre,
      'username': username,
    };
  }
}