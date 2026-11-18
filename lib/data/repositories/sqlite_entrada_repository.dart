import 'package:sqflite/sqflite.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/entrada.dart';
import '../../domain/entities/observacion.dart';
import '../../domain/entities/visita.dart';
import '../../domain/repositories/entrada_repository.dart';
import '../db/app_database.dart';
import '../models/entrada_model.dart';
import '../models/observacion_model.dart';

class SqliteEntradaRepository implements EntradaRepository {
  final AppDatabase _appDb;

  SqliteEntradaRepository(this._appDb);

  @override
  Future<List<Entrada>> obtenerPorUbicacion(int ubicacionId) async {
    try {
      final db = await _appDb.database;
      return await _entradasConFotos(db, ubicacionId, ascendente: false);
    } catch (e) {
      throw AppException('No se pudieron cargar las entradas.', causa: e);
    }
  }

  @override
  Future<List<Visita>> obtenerVisitas(int ubicacionId) async {
    try {
      final db = await _appDb.database;
      // Tres consultas por lugar (entradas, fotos, observaciones), sin N+1 (D-026).
      final entradas = await _entradasConFotos(db, ubicacionId, ascendente: true);

      final filasObs = await db.rawQuery('''
        SELECT o.*
        FROM ${AppDatabase.tablaObservaciones} o
        JOIN ${AppDatabase.tablaEntradas} e ON e.id = o.entrada_id
        WHERE e.ubicacion_id = ?
        ORDER BY o.entrada_id, o.creada_en
      ''', [ubicacionId]);
      final obsPorEntrada = <int, List<Observacion>>{};
      for (final m in filasObs) {
        final o = ObservacionModel.fromMap(m);
        obsPorEntrada.putIfAbsent(o.entradaId, () => []).add(o);
      }

      return entradas
          .map((e) => Visita(
              entrada: e, observaciones: obsPorEntrada[e.id] ?? const []))
          .toList();
    } catch (e) {
      throw AppException('No se pudo cargar la conversación.', causa: e);
    }
  }

  @override
  Future<Entrada?> obtenerMasReciente(int ubicacionId) async {
    try {
      final db = await _appDb.database;
      final filas = await db.query(
        AppDatabase.tablaEntradas,
        where: 'ubicacion_id = ?',
        whereArgs: [ubicacionId],
        orderBy: 'creada_en DESC, id DESC',
        limit: 1,
      );
      if (filas.isEmpty) return null;
      final id = filas.first['id'] as int;
      final fotos = await db.query(AppDatabase.tablaFotos,
          columns: ['ruta'],
          where: 'entrada_id = ?',
          whereArgs: [id],
          orderBy: 'orden');
      return EntradaModel.fromMap(filas.first,
          fotos: fotos.map((f) => f['ruta'] as String).toList());
    } catch (e) {
      throw AppException('No se pudo cargar la última entrada.', causa: e);
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

  /// Entradas del lugar con sus fotos (dos consultas).
  Future<List<Entrada>> _entradasConFotos(Database db, int ubicacionId,
      {required bool ascendente}) async {
    final orden = ascendente ? 'ASC' : 'DESC';
    final filas = await db.query(
      AppDatabase.tablaEntradas,
      where: 'ubicacion_id = ?',
      whereArgs: [ubicacionId],
      orderBy: 'creada_en $orden, id $orden',
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
  }
}
