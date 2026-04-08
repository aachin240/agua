import 'package:sqflite/sqflite.dart';

import '../../models/lectura.dart';
import 'database_service.dart';

class LecturaLocalService {
  Future<Database> get _db async => DatabaseService.instance.database;

  // =========================
  // CUENTAS LOCALES
  // =========================

  Future<void> guardarCuentasIniciales(List<Lectura> lecturas) async {
    final db = await _db;
    final batch = db.batch();

    for (final lectura in lecturas) {
      batch.insert(
        'cuenta_local',
        {
          'id_cuenta': lectura.idCuenta,
          'codigo_cuenta': lectura.codigoCuenta,
          'numero_medidor': lectura.numeroMedidor,
          'id_propietario': lectura.idPropietario,
          'telefono_contacto': lectura.telefonoContacto,
          'direccion_servicio': lectura.direccionServicio,
          'lectura_anterior': lectura.lecturaAnterior,
          'lectura_actual': lectura.lecturaActual,
          'consumo_m3': lectura.consumoM3,
          'fecha_lectura': lectura.fechaLectura?.toString(),
          'id_lectura': lectura.idLectura,
          'id_periodo': lectura.idPeriodo,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Lectura>> listarTodo() async {
    final db = await _db;

    final result = await db.query(
      'cuenta_local',
      orderBy: 'numero_medidor ASC',
    );

    return result.map((e) => Lectura.fromJson(e)).toList();
  }

  Future<Lectura?> buscarPorMedidor(String numeroMedidor) async {
    final db = await _db;

    final result = await db.query(
      'cuenta_local',
      where: 'numero_medidor = ?',
      whereArgs: [numeroMedidor],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Lectura.fromJson(result.first);
  }

  Future<void> actualizarCuentaLocalDespuesDeLectura({
    required String numeroMedidor,
    required num lecturaAnterior,
    required num lecturaActual,
    required num consumoM3,
    required String fechaLectura,
  }) async {
    final db = await _db;

    await db.update(
      'cuenta_local',
      {
        'lectura_anterior': lecturaAnterior,
        'lectura_actual': lecturaActual,
        'consumo_m3': consumoM3,
        'fecha_lectura': fechaLectura,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'numero_medidor = ?',
      whereArgs: [numeroMedidor],
    );
  }

  // =========================
  // LECTURAS PENDIENTES
  // =========================

  Future<void> guardarLecturaPendiente({
    required int idCuenta,
    required String numeroMedidor,
    required num lecturaAnterior,
    required num lecturaActual,
    required num consumoM3,
    required String fechaLectura,
    required String fotoPathLocal,
    String? usuarioRegistro,
    String? observacion,
    double? latitudGps,
    double? longitudGps,
  }) async {
    final db = await _db;

    await db.insert(
      'lectura_pendiente',
      {
        'id_cuenta': idCuenta,
        'numero_medidor': numeroMedidor,
        'lectura_anterior': lecturaAnterior,
        'lectura_actual': lecturaActual,
        'consumo_m3': consumoM3,
        'fecha_lectura': fechaLectura,
        'usuario_registro': usuarioRegistro ?? 'app',
        'observacion': observacion,
        'latitud_gps': latitudGps,
        'longitud_gps': longitudGps,
        'foto_path_local': fotoPathLocal,
        'pendiente_sync': 1,
        'estado_sync': 'pending',
        'updated_local_at': DateTime.now().toIso8601String(),
        'sync_error': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Lectura>> obtenerPendientesSync() async {
    final db = await _db;

    final result = await db.query(
      'lectura_pendiente',
      where: 'pendiente_sync = 1',
      orderBy: 'updated_local_at ASC',
    );

    return result.map((e) => Lectura.fromJson(e)).toList();
  }

  Future<void> marcarComoSincronizado(int idLocal) async {
    final db = await _db;

    await db.update(
      'lectura_pendiente',
      {
        'pendiente_sync': 0,
        'estado_sync': 'synced',
        'synced_at': DateTime.now().toIso8601String(),
        'sync_error': null,
      },
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }

  Future<void> marcarComoError(int idLocal, String error) async {
    final db = await _db;

    await db.update(
      'lectura_pendiente',
      {
        'pendiente_sync': 1,
        'estado_sync': 'error',
        'sync_error': error,
      },
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }

  Future<void> eliminarPendiente(int idLocal) async {
    final db = await _db;

    await db.delete(
      'lectura_pendiente',
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }

  Future<void> limpiarCuentasLocales() async {
    final db = await _db;
    await db.delete('cuenta_local');
  }

  Future<void> marcarComoSincronizando(int idLocal) async {
    final db = await _db;

    await db.update(
      'lectura_pendiente',
      {
        'estado_sync': 'syncing',
        'sync_error': null,
      },
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }

  Future<int> contarPendientes() async {
    final db = await _db;

    final result = await db.rawQuery('''
    SELECT COUNT(*) AS total
    FROM lectura_pendiente
    WHERE pendiente_sync = 1
  ''');

    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> contarErrores() async {
    final db = await _db;

    final result = await db.rawQuery('''
    SELECT COUNT(*) AS total
    FROM lectura_pendiente
    WHERE estado_sync IN ('error', 'conflict')
  ''');

    return (result.first['total'] as int?) ?? 0;
  }

  Future<List<Lectura>> obtenerConError() async {
    final db = await _db;

    final result = await db.query(
      'lectura_pendiente',
      where: "estado_sync IN ('error', 'conflict')",
      orderBy: 'updated_local_at ASC',
    );

    return result.map((e) => Lectura.fromJson(e)).toList();
  }
}