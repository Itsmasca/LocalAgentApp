import '../../core/errors/app_exception.dart';
import '../../domain/entities/observacion.dart';
import '../../domain/repositories/observacion_repository.dart';
import '../db/app_database.dart';
import '../models/observacion_model.dart';

class SqliteObservacionRepository implements ObservacionRepository {
  final AppDatabase _appDb;

  SqliteObservacionRepository(this._appDb);

  @override
  Future<Observacion> crear(Observacion observacion) async {
    try {
      final db = await _appDb.database;
      final id = await db.insert(
          AppDatabase.tablaObservaciones, ObservacionModel.toMap(observacion));
      return observacion.copyWith(id: id);
    } catch (e) {
      throw AppException('No se pudo guardar la observación.', causa: e);
    }
  }

  @override
  Future<void> eliminar(int id) async {
    try {
      final db = await _appDb.database;
      await db.delete(AppDatabase.tablaObservaciones,
          where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw AppException('No se pudo eliminar la observación.', causa: e);
    }
  }
}
