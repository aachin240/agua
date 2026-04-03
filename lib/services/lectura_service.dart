import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lectura.dart';

class LecturaService {
  static const String baseUrl =
      //'http://10.0.2.2:8093/scriptcase/app/agua/web_service_lectura/';
      'http://192.168.1.5:8093/scriptcase/app/agua/web_service_lectura/';
      //'http://10.201.51.59:8093/scriptcase/app/agua/web_service_lectura/';

  Future<List<Lectura>> listarTodo() async {
    final uri = Uri.parse(baseUrl);
    final response = await http.get(uri);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['ok'] == true) {
      final lista = data['data'] as List<dynamic>;
      return lista.map((e) => Lectura.fromJson(e)).toList();
    }

    throw Exception(data['mensaje'] ?? 'Error al listar');
  }

  Future<Lectura> buscarPorMedidor(String numeroMedidor) async {
    final uri = Uri.parse('${baseUrl}?numero_medidor=$numeroMedidor');
    final response = await http.get(uri);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['ok'] == true) {
      return Lectura.fromJson(data['data']);
    }

    throw Exception(data['mensaje'] ?? 'No encontrado');
  }

  Future<String> actualizarLectura({
    required String numeroMedidor,
    required int lecturaActual,
    required String fechaLectura,
    double? latitudGps,
    double? longitudGps,
    String? fotoPathLocal,
    String? fotoFechaToma,
    double? fotoLatitud,
    double? fotoLongitud,
  }) async {
    final uri = Uri.parse(baseUrl);

    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'numero_medidor': numeroMedidor,
        'lectura_actual': lecturaActual,
        'fecha_lectura': fechaLectura,
        'latitud_gps': latitudGps,
        'longitud_gps': longitudGps,
        'foto_path_local': fotoPathLocal ?? '',
        'foto_fecha_toma': fotoFechaToma,
        'foto_latitud': fotoLatitud,
        'foto_longitud': fotoLongitud,
        'usuario_actualizo': '',
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['ok'] == true) {
      return data['mensaje'] ?? 'Actualizado correctamente';
    }

    throw Exception(data['mensaje'] ?? 'Error al actualizar');
  }
}