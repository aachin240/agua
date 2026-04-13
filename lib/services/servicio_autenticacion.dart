import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/configuracion_web_service.dart';
import '../models/usuario_sesion.dart';

class ServicioAutenticacion {
  Future<UsuarioSesion> login({
    required String username,
    required String password,
  }) async {
    final uri = ConfiguracionWebService.loginUri();

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