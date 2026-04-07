import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbFolder = await getDatabasesPath();
    final dbPath = join(dbFolder, 'agua_local.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lectura_local (
        id_local INTEGER PRIMARY KEY AUTOINCREMENT,
        id_remoto INTEGER,
        nombre TEXT,
        direccion TEXT,
        telefono TEXT,
        numero_medidor TEXT NOT NULL UNIQUE,
        lectura_anterior INTEGER,
        lectura_actual INTEGER,
        fecha_lectura TEXT,
        latitud_gps REAL,
        longitud_gps REAL,
        foto_path_local TEXT,
        foto_fecha_toma TEXT,
        foto_latitud REAL,
        foto_longitud REAL,
        usuario_actualizo TEXT,
        pendiente_sync INTEGER NOT NULL DEFAULT 0,
        estado_sync TEXT NOT NULL DEFAULT 'synced',
        updated_local_at TEXT,
        synced_at TEXT,
        sync_error TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_lectura_numero_medidor
      ON lectura_local (numero_medidor)
    ''');

    await db.execute('''
      CREATE INDEX idx_lectura_pendiente_sync
      ON lectura_local (pendiente_sync)
    ''');
  }
}