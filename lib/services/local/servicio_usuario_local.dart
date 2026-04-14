import 'package:sqflite/sqflite.dart';

import '../../models/usuario_sesion.dart';
import 'servicio_base_datos.dart';

class ServicioUsuarioLocal {
  Future<Database> get _db async => ServicioBaseDatos.instance.database;

  Future<void> guardarUsuarioAutorizado({
    required UsuarioSesion usuario,
    required String clave,
  }) async {
    final db = await _db;

    await db.insert(
      'usuario_offline',
      {
        'username': usuario.username.trim(),
        'id_usuario': usuario.idUsuario,
        'nombre': usuario.nombre.trim(),
        'clave_local': clave,
        'autorizado': 1,
        'ultimo_login_online': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UsuarioSesion?> validarLoginOffline({
    required String username,
    required String clave,
  }) async {
    final db = await _db;

    final result = await db.query(
      'usuario_offline',
      where: 'username = ? AND clave_local = ? AND autorizado = 1',
      whereArgs: [username.trim(), clave],
      limit: 1,
    );

    if (result.isEmpty) return null;

    await db.update(
      'usuario_offline',
      {
        'ultimo_login_offline': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'username = ?',
      whereArgs: [username.trim()],
    );

    final row = result.first;

    return UsuarioSesion(
      idUsuario: int.parse(row['id_usuario'].toString()),
      nombre: (row['nombre'] ?? '').toString(),
      username: (row['username'] ?? '').toString(),
    );
  }

  Future<bool> existeUsuarioAutorizado(String username) async {
    final db = await _db;

    final result = await db.query(
      'usuario_offline',
      columns: ['username'],
      where: 'username = ? AND autorizado = 1',
      whereArgs: [username.trim()],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<void> guardarRutasActivas({
    required String username,
    required List<int> rutas,
  }) async {
    final db = await _db;
    final batch = db.batch();

    batch.delete(
      'ruta_activa_usuario',
      where: 'username = ?',
      whereArgs: [username.trim()],
    );

    final ahora = DateTime.now().toIso8601String();

    for (final ruta in rutas.toSet().toList()..sort()) {
      batch.insert(
        'ruta_activa_usuario',
        {
          'username': username.trim(),
          'ruta': ruta,
          'activa': 1,
          'updated_at': ahora,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<int>> obtenerRutasActivas(String username) async {
    final db = await _db;

    final result = await db.query(
      'ruta_activa_usuario',
      columns: ['ruta'],
      where: 'username = ? AND activa = 1',
      whereArgs: [username.trim()],
      orderBy: 'ruta ASC',
    );

    return result
        .map((e) => int.tryParse(e['ruta'].toString()) ?? 0)
        .where((e) => e > 0)
        .toList();
  }

  Future<void> limpiarRutasActivas(String username) async {
    final db = await _db;

    await db.delete(
      'ruta_activa_usuario',
      where: 'username = ?',
      whereArgs: [username.trim()],
    );
  }

  Future<void> eliminarUsuarioAutorizado(String username) async {
    final db = await _db;
    final batch = db.batch();

    batch.delete(
      'ruta_activa_usuario',
      where: 'username = ?',
      whereArgs: [username.trim()],
    );

    batch.delete(
      'usuario_offline',
      where: 'username = ?',
      whereArgs: [username.trim()],
    );

    await batch.commit(noResult: true);
  }
}