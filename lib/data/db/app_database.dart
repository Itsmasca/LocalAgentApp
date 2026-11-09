import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Abre (una sola vez) la base SQLite local y crea el esquema.
class AppDatabase {
  static const _nombreArchivo = 'bitacora_campo.db';
  static const _version = 1;

  static const tablaUbicaciones = 'ubicaciones';
  static const tablaEntradas = 'entradas';

  Database? _db;

  Future<Database> get database async => _db ??= await _abrir();

  Future<Database> _abrir() async {
    final ruta = p.join(await getDatabasesPath(), _nombreArchivo);
    return openDatabase(
      ruta,
      version: _version,
      // Necesario para que ON DELETE CASCADE funcione en SQLite.
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _crearEsquema,
    );
  }

  Future<void> _crearEsquema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablaUbicaciones (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre        TEXT    NOT NULL,
        latitud       REAL    NOT NULL,
        longitud      REAL    NOT NULL,
        radio_metros  REAL    NOT NULL DEFAULT 75,
        foto_portada  TEXT,
        creada_en     TEXT    NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $tablaEntradas (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        ubicacion_id  INTEGER NOT NULL
                      REFERENCES $tablaUbicaciones(id) ON DELETE CASCADE,
        texto         TEXT    NOT NULL,
        imagen_path   TEXT,
        latitud       REAL    NOT NULL,
        longitud      REAL    NOT NULL,
        creada_en     TEXT    NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_entradas_ubicacion ON $tablaEntradas(ubicacion_id)');
  }
}
