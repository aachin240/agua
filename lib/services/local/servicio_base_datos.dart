import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ServicioBaseDatos {
  ServicioBaseDatos._();
  static final ServicioBaseDatos instance = ServicioBaseDatos._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('agua_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await _crearTablaCuentaLocal(db);
    await _crearTablaLecturaPendiente(db);
    await _crearTablaUsuarioOffline(db);
    await _crearTablaRutaActivaUsuario(db);
    await _crearIndices(db);
  }

  Future<void> _crearTablaCuentaLocal(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cuenta_local (
        id_local INTEGER PRIMARY KEY AUTOINCREMENT,
        username_owner TEXT NOT NULL,
        id_cuenta INTEGER NOT NULL,
        codigo_cuenta TEXT,
        numero_medidor TEXT NOT NULL,
        id_propietario INTEGER,
        telefono_contacto TEXT,
        direccion_servicio TEXT,
        ruta INTEGER,
        lectura_anterior REAL,
        lectura_actual REAL,
        consumo_m3 REAL,
        fecha_lectura TEXT,
        id_lectura INTEGER,
        id_periodo INTEGER,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _crearTablaLecturaPendiente(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lectura_pendiente (
        id_local INTEGER PRIMARY KEY AUTOINCREMENT,
        username_owner TEXT NOT NULL,
        id_cuenta INTEGER NOT NULL,
        numero_medidor TEXT NOT NULL,
        lectura_anterior REAL NOT NULL,
        lectura_actual REAL NOT NULL,
        consumo_m3 REAL NOT NULL,
        fecha_lectura TEXT NOT NULL,
        usuario_registro TEXT,
        observacion TEXT,
        latitud_gps REAL,
        longitud_gps REAL,
        foto_path_local TEXT NOT NULL,
        pendiente_sync INTEGER NOT NULL DEFAULT 1,
        estado_sync TEXT NOT NULL DEFAULT 'pending',
        updated_local_at TEXT,
        synced_at TEXT,
        sync_error TEXT
      )
    ''');
  }

  Future<void> _crearTablaUsuarioOffline(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuario_offline (
        username TEXT PRIMARY KEY,
        id_usuario INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        clave_local TEXT NOT NULL,
        autorizado INTEGER NOT NULL DEFAULT 1,
        ultimo_login_online TEXT,
        ultimo_login_offline TEXT,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _crearTablaRutaActivaUsuario(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ruta_activa_usuario (
        id_local INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        ruta INTEGER NOT NULL,
        activa INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL,
        UNIQUE(username, ruta)
      )
    ''');
  }

  Future<void> _crearIndices(Database db) async {
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS ux_cuenta_local_owner_cuenta
      ON cuenta_local(username_owner, id_cuenta)
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS ux_cuenta_local_owner_medidor
      ON cuenta_local(username_owner, numero_medidor)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS ix_cuenta_local_owner_ruta
      ON cuenta_local(username_owner, ruta)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS ix_lectura_pendiente_owner_estado
      ON lectura_pendiente(username_owner, pendiente_sync, estado_sync)
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS ux_lectura_pendiente_owner_medidor_fecha
      ON lectura_pendiente(username_owner, numero_medidor, fecha_lectura)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS ix_usuario_offline_username
      ON usuario_offline(username)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS ix_ruta_activa_usuario_username
      ON ruta_activa_usuario(username)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      // Como cambia la estructura local a multiusuario,
      // reiniciamos solo la caché local del dispositivo.
      await db.execute('DROP TABLE IF EXISTS cuenta_local');
      await db.execute('DROP TABLE IF EXISTS lectura_pendiente');
      await db.execute('DROP TABLE IF EXISTS usuario_offline');
      await db.execute('DROP TABLE IF EXISTS ruta_activa_usuario');

      await _createDB(db, newVersion);
    }
  }
}