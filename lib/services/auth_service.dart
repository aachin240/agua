import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/usuario_sesion.dart';

class AuthService {
  static const String loginUrl =
      'http://192.168.1.5:8093/scriptcase/app/agua_potable/ws_agua_login/';

  Future<UsuarioSesion> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse(loginUrl);

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim(),
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('El servidor respondió con un error');
    }

    final body = response.body.trim();

    if (body.startsWith('<!DOCTYPE') || body.startsWith('<html')) {
      throw Exception('El servicio no respondió correctamente');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;

    if (data['ok'] == true) {
      final usuario = Map<String, dynamic>.from(data['data']);
      return UsuarioSesion.fromJson(usuario);
    }

    throw Exception(
      (data['mensaje'] ?? 'No se pudo iniciar sesión').toString(),
    );
  }
}