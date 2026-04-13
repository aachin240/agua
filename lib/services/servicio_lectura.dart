import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/configuracion_web_service.dart';
import '../models/lectura.dart';

class ServicioLectura {
  Future<List<Lectura>> listarTodo() async {
    final uri = ConfiguracionWebService.lecturaUri();
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('El servidor respondió con un error');
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
    required String usuarioRegistro,
    double? latitudGps,
    double? longitudGps,
    String? observacion,
    String? fotoPathLocal,
  }) async {
    final uri = ConfiguracionWebService.lecturaUri();

    String? fotoBase64;

    if (fotoPathLocal != null && fotoPathLocal.trim().isNotEmpty) {
      final file = File(fotoPathLocal);

      if (!await file.exists()) {
        throw Exception('No se encontró la foto guardada en el dispositivo');
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
      'usuario_registro': usuarioRegistro,
      'foto_base64': fotoBase64,
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('El servidor respondió con un error');
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
      _traducirMensajeError(
        data['mensaje']?.toString() ?? 'Error al sincronizar',
      ),
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