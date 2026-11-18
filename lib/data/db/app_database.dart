import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Abre (una sola vez) la base SQLite local, crea el esquema y lo migra.
///
/// Versiones:
/// - 1: cada entrada tenía una sola foto en `entradas.imagen_path`.
/// - 2: las fotos viven en la tabla `fotos` (varias por entrada).
///   En bases migradas la columna `imagen_path` sigue existiendo pero
///   ya no se lee ni se escribe.
/// - 3: tabla `ajustes` (clave-valor) para el responsable, la preferencia
///   de coordenadas y el folio de los reportes (spec 003, D-019).
/// - 4: tabla `observaciones`, notas breves ligadas a una entrada
///   (spec 004, D-024).
class AppDatabase {
  static const _nombreArchivo = 'bitacora_campo.db';
  static const _version = 4;

  static const tablaUbicaciones = 'ubicaciones';
  static const tablaEntradas = 'entradas';
  static const tablaFotos = 'fotos';
  static const tablaAjustes = 'ajustes';
  static const tablaObservaciones = 'observaciones';

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
      onUpgrade: _migrar,
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
        latitud       REAL    NOT NULL,
        longitud      REAL    NOT NULL,
        creada_en     TEXT    NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_entradas_ubicacion ON $tablaEntradas(ubicacion_id)');
    await _crearTablaFotos(db);
    await _crearTablaAjustes(db);
    await _crearTablaObservaciones(db);
  }

  Future<void> _migrar(Database db, int deVersion, int aVersion) async {
    if (deVersion < 2) {
      await _crearTablaFotos(db);
      // Cada foto única de la v1 pasa a ser la foto 0 de su entrada.
      await db.execute('''
        INSERT INTO $tablaFotos (entrada_id, ruta, orden)
        SELECT id, imagen_path, 0 FROM $tablaEntradas
        WHERE imagen_path IS NOT NULL
      ''');
    }
    if (deVersion < 3) {
      await _crearTablaAjustes(db);
    }
    if (deVersion < 4) {
      // Las entradas existentes simplemente no tienen observaciones.
      await _crearTablaObservaciones(db);
    }
  }

  Future<void> _crearTablaObservaciones(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tablaObservaciones (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        entrada_id  INTEGER NOT NULL
                    REFERENCES $tablaEntradas(id) ON DELETE CASCADE,
        texto       TEXT    NOT NULL,
        creada_en   TEXT    NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_observaciones_entrada '
        'ON $tablaObservaciones(entrada_id, creada_en)');
  }

  Future<void> _crearTablaAjustes(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tablaAjustes (
        clave  TEXT PRIMARY KEY,
        valor  TEXT NOT NULL
      )
    ''');
  }

  Future<void> _crearTablaFotos(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tablaFotos (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        entrada_id  INTEGER NOT NULL
                    REFERENCES $tablaEntradas(id) ON DELETE CASCADE,
        ruta        TEXT    NOT NULL,
        orden       INTEGER NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_fotos_entrada ON $tablaFotos(entrada_id, orden)');
  }
}
