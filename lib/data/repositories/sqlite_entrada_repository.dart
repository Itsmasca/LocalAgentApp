import '../../core/errors/app_exception.dart';
import '../../domain/entities/entrada.dart';
import '../../domain/repositories/entrada_repository.dart';
import '../db/app_database.dart';
import '../models/entrada_model.dart';

class SqliteEntradaRepository implements EntradaRepository {
  final AppDatabase _appDb;

  SqliteEntradaRepository(this._appDb);

  @override
  Future<List<Entrada>> obtenerPorUbicacion(int ubicacionId) async {
    try {
      final db = await _appDb.database;
      final filas = await db.query(
        AppDatabase.tablaEntradas,
        where: 'ubicacion_id = ?',
        whereArgs: [ubicacionId],
        orderBy: 'creada_en DESC',
      );
      return filas.map(EntradaModel.fromMap).toList();
    } catch (e) {
      throw AppException('No se pudieron cargar las entradas.', causa: e);
    }
  }

  @override
  Future<Entrada> crear(Entrada entrada) async {
    try {
      final db = await _appDb.database;
      final id =
          await db.insert(AppDatabase.tablaEntradas, EntradaModel.toMap(entrada));
      return entrada.copyWith(id: id);
    } catch (e) {
      throw AppException('No se pudo guardar la entrada.', causa: e);
    }
  }
}
