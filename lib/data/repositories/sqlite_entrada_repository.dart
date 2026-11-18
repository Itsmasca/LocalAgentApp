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

      // Todas las fotos del lugar en una sola consulta, agrupadas por entrada.
      final filasFotos = await db.rawQuery('''
        SELECT f.entrada_id, f.ruta
        FROM ${AppDatabase.tablaFotos} f
        JOIN ${AppDatabase.tablaEntradas} e ON e.id = f.entrada_id
        WHERE e.ubicacion_id = ?
        ORDER BY f.entrada_id, f.orden
      ''', [ubicacionId]);
      final fotosPorEntrada = <int, List<String>>{};
      for (final f in filasFotos) {
        fotosPorEntrada
            .putIfAbsent(f['entrada_id'] as int, () => [])
            .add(f['ruta'] as String);
      }

      return filas
          .map((m) => EntradaModel.fromMap(m,
              fotos: fotosPorEntrada[m['id'] as int] ?? const []))
          .toList();
    } catch (e) {
      throw AppException('No se pudieron cargar las entradas.', causa: e);
    }
  }

  @override
  Future<Entrada> crear(Entrada entrada) async {
    try {
      final db = await _appDb.database;
      return await db.transaction((txn) async {
        final id = await txn.insert(
            AppDatabase.tablaEntradas, EntradaModel.toMap(entrada));
        await EntradaModel.insertarFotos(txn, id, entrada.fotos);
        return entrada.copyWith(id: id);
      });
    } catch (e) {
      throw AppException('No se pudo guardar la entrada.', causa: e);
    }
  }
}
