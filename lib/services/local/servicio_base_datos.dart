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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Catálogo local para mostrar y buscar cuentas sin conexión
    await db.execute('''
      CREATE TABLE cuenta_local (
        id_cuenta INTEGER PRIMARY KEY,
        codigo_cuenta TEXT,
        numero_medidor TEXT NOT NULL UNIQUE,
        id_propietario INTEGER,
        telefono_contacto TEXT,
        direccion_servicio TEXT,
        lectura_anterior REAL,
        lectura_actual REAL,
        consumo_m3 REAL,
        fecha_lectura TEXT,
        id_lectura INTEGER,
        id_periodo INTEGER,
        updated_at TEXT
      )
    ''');

    // Lecturas tomadas offline y pendientes de sincronizar
    await db.execute('''
      CREATE TABLE lectura_pendiente (
        id_local INTEGER PRIMARY KEY AUTOINCREMENT,
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

    await db.execute('''
      CREATE INDEX ix_cuenta_local_medidor
      ON cuenta_local(numero_medidor)
    ''');

    await db.execute('''
      CREATE INDEX ix_lectura_pendiente_estado
      ON lectura_pendiente(pendiente_sync, estado_sync)
    ''');

    // Evita registrar dos lecturas locales del mismo medidor en la misma fecha
    await db.execute('''
      CREATE UNIQUE INDEX ux_lectura_pendiente_medidor_fecha
      ON lectura_pendiente(numero_medidor, fecha_lectura)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS lectura_pendiente');
      await db.execute('DROP TABLE IF EXISTS cuenta_local');
      await _createDB(db, newVersion);
    }
  }
}