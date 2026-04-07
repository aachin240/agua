import 'package:sqflite/sqflite.dart';
import '../../models/lectura.dart';
import 'database_service.dart';

class LecturaLocalService {
  Future<Database> get _db async => await DatabaseService.instance.database;

  Future<void> guardarLecturasIniciales(List<Lectura> lecturas) async {
    final db = await _db;
    final batch = db.batch();

    for (final lectura in lecturas) {
      batch.insert(
        'lectura_local',
        {
          'id_remoto': lectura.id,
          'nombre': lectura.nombre,
          'direccion': lectura.direccion,
          'telefono': lectura.telefono,
          'numero_medidor': lectura.numeroMedidor,
          'lectura_anterior': lectura.lecturaAnterior,
          'lectura_actual': lectura.lecturaActual,
          'fecha_lectura': lectura.fechaLectura?.toString(),
          'latitud_gps': lectura.latitudGps,
          'longitud_gps': lectura.longitudGps,
          'foto_path_local': lectura.fotoPathLocal?.toString(),
          'foto_fecha_toma': lectura.fotoFechaToma?.toString(),
          'foto_latitud': lectura.fotoLatitud,
          'foto_longitud': lectura.fotoLongitud,
          'usuario_actualizo': lectura.usuarioActualizo?.toString(),
          'pendiente_sync': 0,
          'estado_sync': 'synced',
          'updated_local_at': null,
          'synced_at': DateTime.now().toIso8601String(),
          'sync_error': null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Lectura>> listarTodo() async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT
        id_remoto AS id,
        nombre,
        direccion,
        telefono,
        numero_medidor,
        lectura_anterior,
        lectura_actual,
        fecha_lectura,
        latitud_gps,
        longitud_gps,
        foto_path_local,
        foto_fecha_toma,
        foto_latitud,
        foto_longitud,
        usuario_actualizo
      FROM lectura_local
      ORDER BY id_local
    ''');

    return result.map((e) => Lectura.fromJson(e)).toList();
  }

  Future<Lectura?> buscarPorMedidor(String numeroMedidor) async {
    final db = await _db;

    final result = await db.rawQuery(
      '''
      SELECT
        id_remoto AS id,
        nombre,
        direccion,
        telefono,
        numero_medidor,
        lectura_anterior,
        lectura_actual,
        fecha_lectura,
        latitud_gps,
        longitud_gps,
        foto_path_local,
        foto_fecha_toma,
        foto_latitud,
        foto_longitud,
        usuario_actualizo
      FROM lectura_local
      WHERE numero_medidor = ?
      LIMIT 1
      ''',
      [numeroMedidor],
    );

    if (result.isEmpty) return null;

    return Lectura.fromJson(result.first);
  }

  Future<void> actualizarLecturaLocal({
    required String numeroMedidor,
    required int lecturaActual,
    required String fechaLectura,
    double? latitudGps,
    double? longitudGps,
    String? fotoPathLocal,
    String? fotoFechaToma,
    double? fotoLatitud,
    double? fotoLongitud,
    String? usuarioActualizo,
  }) async {
    final db = await _db;

    final filas = await db.update(
      'lectura_local',
      {
        'lectura_actual': lecturaActual,
        'fecha_lectura': fechaLectura,
        'latitud_gps': latitudGps,
        'longitud_gps': longitudGps,
        'foto_path_local': fotoPathLocal,
        'foto_fecha_toma': fotoFechaToma,
        'foto_latitud': fotoLatitud,
        'foto_longitud': fotoLongitud,
        'usuario_actualizo': usuarioActualizo,
        'pendiente_sync': 1,
        'estado_sync': 'pending',
        'updated_local_at': DateTime.now().toIso8601String(),
        'sync_error': null,
      },
      where: 'numero_medidor = ?',
      whereArgs: [numeroMedidor],
    );

    if (filas == 0) {
      throw Exception('No existe ese número de medidor en SQLite');
    }
  }

  Future<List<Lectura>> obtenerPendientesSync() async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT
        id_remoto AS id,
        nombre,
        direccion,
        telefono,
        numero_medidor,
        lectura_anterior,
        lectura_actual,
        fecha_lectura,
        latitud_gps,
        longitud_gps,
        foto_path_local,
        foto_fecha_toma,
        foto_latitud,
        foto_longitud,
        usuario_actualizo
      FROM lectura_local
      WHERE pendiente_sync = 1
      ORDER BY updated_local_at ASC
    ''');

    return result.map((e) => Lectura.fromJson(e)).toList();
  }

  Future<void> marcarComoSincronizado(String numeroMedidor) async {
    final db = await _db;

    await db.update(
      'lectura_local',
      {
        'pendiente_sync': 0,
        'estado_sync': 'synced',
        'synced_at': DateTime.now().toIso8601String(),
        'sync_error': null,
      },
      where: 'numero_medidor = ?',
      whereArgs: [numeroMedidor],
    );
  }

  Future<void> marcarComoErrorSync(
      String numeroMedidor,
      String error,
      ) async {
    final db = await _db;

    await db.update(
      'lectura_local',
      {
        'pendiente_sync': 1,
        'estado_sync': 'error',
        'sync_error': error,
      },
      where: 'numero_medidor = ?',
      whereArgs: [numeroMedidor],
    );
  }
}