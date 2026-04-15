import 'package:sqflite/sqflite.dart';

import '../../models/lectura.dart';
import 'servicio_base_datos.dart';

class ServicioLecturaLocal {
  Future<Database> get _db async => ServicioBaseDatos.instance.database;

  // =========================
  // CUENTAS LOCALES
  // =========================

  Future<void> guardarCuentasIniciales({
    required String usernameOwner,
    required List<Lectura> lecturas,
    bool reemplazarExistentes = true,
  }) async {
    final db = await _db;
    final batch = db.batch();

    if (reemplazarExistentes) {
      batch.delete(
        'cuenta_local',
        where: 'username_owner = ?',
        whereArgs: [usernameOwner],
      );
    }

    final ahora = DateTime.now().toIso8601String();

    for (final lectura in lecturas) {
      batch.insert(
        'cuenta_local',
        {
          'username_owner': usernameOwner,
          'id_cuenta': lectura.idCuenta,
          'codigo_cuenta': lectura.codigoCuenta,
          'numero_medidor': lectura.numeroMedidor,
          'id_propietario': lectura.idPropietario,
          'telefono_contacto': lectura.telefonoContacto,
          'direccion_servicio': lectura.direccionServicio,
          'ruta': lectura.ruta,
          'lectura_anterior': lectura.lecturaAnterior,
          'lectura_actual': lectura.lecturaActual,
          'consumo_m3': lectura.consumoM3,
          'fecha_lectura': lectura.fechaLectura?.toString(),
          'id_lectura': lectura.idLectura,
          'id_periodo': lectura.idPeriodo,
          'updated_at': ahora,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Lectura>> listarTodo({
    required String usernameOwner,
    int? ruta,
  }) async {
    final db = await _db;

    final result = await db.query(
      'cuenta_local',
      where: ruta != null
          ? 'username_owner = ? AND ruta = ?'
          : 'username_owner = ?',
      whereArgs: ruta != null ? [usernameOwner, ruta] : [usernameOwner],
      orderBy: 'numero_medidor ASC',
    );

    return result.map((e) => Lectura.fromJson(e)).toList();
  }

  Future<Lectura?> buscarPorMedidor({
    required String usernameOwner,
    required String numeroMedidor,
  }) async {
    final db = await _db;

    final result = await db.query(
      'cuenta_local',
      where: 'username_owner = ? AND numero_medidor = ?',
      whereArgs: [usernameOwner, numeroMedidor],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Lectura.fromJson(result.first);
  }

  Future<void> actualizarCuentaLocalDespuesDeLectura({
    required String usernameOwner,
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
      where: 'username_owner = ? AND numero_medidor = ?',
      whereArgs: [usernameOwner, numeroMedidor],
    );
  }

  Future<void> limpiarCuentasLocalesDeUsuario(String usernameOwner) async {
    final db = await _db;

    await db.delete(
      'cuenta_local',
      where: 'username_owner = ?',
      whereArgs: [usernameOwner],
    );
  }

  Future<bool> hayCuentasLocalesDeUsuario(String usernameOwner) async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM cuenta_local
      WHERE username_owner = ?
    ''', [usernameOwner]);

    final total = Sqflite.firstIntValue(result) ?? 0;
    return total > 0;
  }

  Future<List<int>> obtenerRutasLocalesDeUsuario(String usernameOwner) async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT DISTINCT ruta
      FROM cuenta_local
      WHERE username_owner = ?
        AND ruta IS NOT NULL
      ORDER BY ruta
    ''', [usernameOwner]);

    return result
        .map((e) => int.tryParse(e['ruta'].toString()) ?? 0)
        .where((e) => e > 0)
        .toList();
  }

  Future<bool> coincidenRutasLocales({
    required String usernameOwner,
    required List<int> rutasEsperadas,
  }) async {
    final rutasLocales = await obtenerRutasLocalesDeUsuario(usernameOwner)
      ..sort();

    final esperadas = [...rutasEsperadas]..sort();

    if (rutasLocales.length != esperadas.length) return false;

    for (int i = 0; i < rutasLocales.length; i++) {
      if (rutasLocales[i] != esperadas[i]) return false;
    }

    return true;
  }

  // =========================
  // LECTURAS PENDIENTES
  // =========================

  Future<void> guardarLecturaPendiente({
    required String usernameOwner,
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
        'username_owner': usernameOwner,
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

  Future<List<Lectura>> obtenerPendientesSync({
    required String usernameOwner,
  }) async {
    final db = await _db;

    final result = await db.query(
      'lectura_pendiente',
      where: 'username_owner = ? AND pendiente_sync = 1',
      whereArgs: [usernameOwner],
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

  Future<int> contarPendientes(String usernameOwner) async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM lectura_pendiente
      WHERE username_owner = ?
        AND pendiente_sync = 1
    ''', [usernameOwner]);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> contarErrores(String usernameOwner) async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM lectura_pendiente
      WHERE username_owner = ?
        AND estado_sync IN ('error', 'conflict')
    ''', [usernameOwner]);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Lectura>> obtenerConError(String usernameOwner) async {
    final db = await _db;

    final result = await db.query(
      'lectura_pendiente',
      where: "username_owner = ? AND estado_sync IN ('error', 'conflict')",
      whereArgs: [usernameOwner],
      orderBy: 'updated_local_at ASC',
    );

    return result.map((e) => Lectura.fromJson(e)).toList();
  }
}