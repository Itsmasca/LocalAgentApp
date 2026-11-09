import '../../core/errors/app_exception.dart';
import '../../domain/entities/entrada.dart';
import '../../domain/entities/ubicacion.dart';
import '../../domain/repositories/ubicacion_repository.dart';
import '../db/app_database.dart';
import '../models/entrada_model.dart';
import '../models/ubicacion_model.dart';

class SqliteUbicacionRepository implements UbicacionRepository {
  final AppDatabase _appDb;

  SqliteUbicacionRepository(this._appDb);

  @override
  Future<List<Ubicacion>> obtenerTodas() async {
    try {
      final db = await _appDb.database;
      // Las ubicaciones con actividad más reciente aparecen primero.
      final filas = await db.rawQuery('''
        SELECT u.*, MAX(e.creada_en) AS ultima
        FROM ${AppDatabase.tablaUbicaciones} u
        LEFT JOIN ${AppDatabase.tablaEntradas} e ON e.ubicacion_id = u.id
        GROUP BY u.id
        ORDER BY COALESCE(ultima, u.creada_en) DESC
      ''');
      return filas.map(UbicacionModel.fromMap).toList();
    } catch (e) {
      throw AppException('No se pudieron cargar las ubicaciones.', causa: e);
    }
  }

  @override
  Future<Ubicacion?> obtenerPorId(int id) async {
    try {
      final db = await _appDb.database;
      final filas = await db.query(AppDatabase.tablaUbicaciones,
          where: 'id = ?', whereArgs: [id], limit: 1);
      return filas.isEmpty ? null : UbicacionModel.fromMap(filas.first);
    } catch (e) {
      throw AppException('No se pudo cargar la ubicación.', causa: e);
    }
  }

  @override
  Future<Ubicacion> crear(Ubicacion ubicacion) async {
    try {
      final db = await _appDb.database;
      final id = await db.insert(
          AppDatabase.tablaUbicaciones, UbicacionModel.toMap(ubicacion));
      return ubicacion.copyWith(id: id);
    } catch (e) {
      throw AppException('No se pudo crear la ubicación.', causa: e);
    }
  }

  @override
  Future<void> actualizarPortada(int id, String rutaImagen) async {
    try {
      final db = await _appDb.database;
      await db.update(AppDatabase.tablaUbicaciones, {'foto_portada': rutaImagen},
          where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw AppException('No se pudo actualizar la portada.', causa: e);
    }
  }

  @override
  Future<Entrada> registrarEntrada({
    Ubicacion? nueva,
    required Entrada entrada,
    bool ponerPortada = false,
  }) async {
    try {
      final db = await _appDb.database;
      // Si cualquier paso falla, SQLite revierte todo lo hecho dentro.
      return await db.transaction((txn) async {
        var ubicacionId = entrada.ubicacionId;
        if (nueva != null) {
          ubicacionId = await txn.insert(
              AppDatabase.tablaUbicaciones, UbicacionModel.toMap(nueva));
        }

        final aGuardar = entrada.copyWith(ubicacionId: ubicacionId);
        final entradaId = await txn.insert(
            AppDatabase.tablaEntradas, EntradaModel.toMap(aGuardar));

        if (ponerPortada && aGuardar.imagenPath != null) {
          await txn.update(
            AppDatabase.tablaUbicaciones,
            {'foto_portada': aGuardar.imagenPath},
            where: 'id = ?',
            whereArgs: [ubicacionId],
          );
        }
        return aGuardar.copyWith(id: entradaId);
      });
    } catch (e) {
      throw AppException('No se pudo guardar la entrada.', causa: e);
    }
  }

  @override
  Future<void> eliminar(int id) async {
    try {
      final db = await _appDb.database;
      // Las entradas se borran en cascada (FOREIGN KEY ... ON DELETE CASCADE).
      await db.delete(AppDatabase.tablaUbicaciones,
          where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw AppException('No se pudo eliminar la ubicación.', causa: e);
    }
  }
}
