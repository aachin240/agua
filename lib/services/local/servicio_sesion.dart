import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/usuario_sesion.dart';

class ServicioSesion {
  static const String _keyUsuarioSesionActiva = 'usuario_sesion_activa';

  Future<void> guardarSesion(UsuarioSesion usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyUsuarioSesionActiva,
      jsonEncode(usuario.toJson()),
    );
  }

  Future<UsuarioSesion?> obtenerSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUsuarioSesionActiva);

    if (raw == null || raw.trim().isEmpty) return null;

    final data = jsonDecode(raw) as Map<String, dynamic>;
    return UsuarioSesion.fromJson(data);
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsuarioSesionActiva);
  }

  Future<bool> haySesionActiva() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyUsuarioSesionActiva);
  }
}