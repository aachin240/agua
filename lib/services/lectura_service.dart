import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/lectura.dart';

class LecturaService {
  static const String baseUrl =
      'http://192.168.1.5:8093/scriptcase/app/agua_potable/ws_agua_lectura/';

  Future<List<Lectura>> listarTodo() async {
    final uri = Uri.parse(baseUrl);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Error HTTP ${response.statusCode}');
    }

    final body = response.body.trim();

    if (body.startsWith('<!DOCTYPE') || body.startsWith('<html')) {
      throw Exception('El servidor devolvió HTML en lugar de JSON');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;

    if (data['ok'] == true) {
      final lista = (data['data'] as List<dynamic>? ?? []);
      return lista
          .map((e) => Lectura.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    throw Exception(data['mensaje'] ?? 'Error al listar cuentas');
  }

  Future<String> registrarLectura({
    required String numeroMedidor,
    required num lecturaActual,
    required String fechaLectura,
    double? latitudGps,
    double? longitudGps,
    String? observacion,
    String? fotoPathLocal,
  }) async {
    final uri = Uri.parse(baseUrl);

    String? fotoBase64;

    if (fotoPathLocal != null && fotoPathLocal.trim().isNotEmpty) {
      final file = File(fotoPathLocal);

      if (!await file.exists()) {
        throw Exception('No existe la foto local');
      }

      final bytes = await file.readAsBytes();
      fotoBase64 = base64Encode(bytes);
    }

    final payload = <String, dynamic>{
      'numero_medidor': numeroMedidor.trim(),
      'lectura_actual': lecturaActual,
      'fecha_lectura': fechaLectura,
      'latitud_gps': latitudGps,
      'longitud_gps': longitudGps,
      'observacion': (observacion ?? '').trim(),
      'usuario_registro': 'app',
      'foto_base64': fotoBase64,
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Error HTTP ${response.statusCode}');
    }

    final body = response.body.trim();

    if (body.startsWith('<!DOCTYPE') || body.startsWith('<html')) {
      throw Exception('El servidor devolvió HTML en lugar de JSON');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;

    if (data['ok'] == true) {
      return data['mensaje'] ?? 'Lectura registrada correctamente';
    }

    throw Exception(
      _traducirMensajeError(data['mensaje']?.toString() ?? 'Error al sincronizar'),
    );
  }

  String _traducirMensajeError(String mensaje) {
    final m = mensaje.toLowerCase();

    if (m.contains('foto_base64')) {
      return 'La foto no se pudo procesar correctamente';
    }

    if (m.contains('cuenta no encontrada')) {
      return 'No se encontró la cuenta para este medidor';
    }

    if (m.contains('ya existe una lectura')) {
      return 'Ya existe una lectura registrada para este período';
    }

    if (m.contains('no existe un período vigente')) {
      return 'No existe un período vigente para la fecha de lectura';
    }

    if (m.contains('la lectura actual no puede ser menor')) {
      return 'La lectura actual debe ser mayor que la anterior';
    }

    if (m.contains('json inválido')) {
      return 'El envío de datos no fue válido';
    }

    return mensaje;
  }
}