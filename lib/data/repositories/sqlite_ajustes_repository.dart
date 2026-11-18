import 'package:sqflite/sqflite.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/responsable.dart';
import '../../domain/repositories/ajustes_repository.dart';
import '../db/app_database.dart';

/// Ajustes en la tabla clave-valor `ajustes` (D-019).
class SqliteAjustesRepository implements AjustesRepository {
  static const _nombre = 'responsable.nombre';
  static const _negocio = 'responsable.negocio';
  static const _telefono = 'responsable.telefono';
  static const _incluirCoordenadas = 'compartir.incluir_coordenadas';
  static const _folioAnio = 'folio.anio';
  static const _folioConsecutivo = 'folio.consecutivo';

  final AppDatabase _appDb;

  SqliteAjustesRepository(this._appDb);

  @override
  Future<Responsable?> obtenerResponsable() async {
    try {
      final db = await _appDb.database;
      final v = await _leerVarios(db, [_nombre, _negocio, _telefono]);
      final nombre = v[_nombre];
      if (nombre == null || nombre.trim().isEmpty) return null;
      return Responsable(
          nombre: nombre, negocio: v[_negocio], telefono: v[_telefono]);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudieron leer tus datos.', causa: e);
    }
  }

  @override
  Future<void> guardarResponsable(Responsable r) async {
    try {
      final db = await _appDb.database;
      await db.transaction((txn) async {
        await _escribir(txn, _nombre, r.nombre);
        await _escribirOBorrar(txn, _negocio, r.negocio);
        await _escribirOBorrar(txn, _telefono, r.telefono);
      });
    } catch (e) {
      throw AppException('No se pudieron guardar tus datos.', causa: e);
    }
  }

  @override
  Future<void> borrarResponsable() async {
    try {
      final db = await _appDb.database;
      await db.delete(AppDatabase.tablaAjustes,
          where: 'clave IN (?, ?, ?)', whereArgs: [_nombre, _negocio, _telefono]);
    } catch (e) {
      throw AppException('No se pudieron borrar tus datos.', causa: e);
    }
  }

  @override
  Future<bool> incluirCoordenadas() async {
    try {
      final db = await _appDb.database;
      final v = await _leer(db, _incluirCoordenadas);
      return v != '0'; // por defecto: sí
    } catch (e) {
      throw AppException('No se pudieron leer los ajustes.', causa: e);
    }
  }

  @override
  Future<void> guardarIncluirCoordenadas(bool valor) async {
    try {
      final db = await _appDb.database;
      await _escribir(db, _incluirCoordenadas, valor ? '1' : '0');
    } catch (e) {
      throw AppException('No se pudieron guardar los ajustes.', causa: e);
    }
  }

  @override
  Future<String> reservarFolio(DateTime fecha) async {
    try {
      final db = await _appDb.database;
      return await db.transaction((txn) async {
        final anioGuardado = int.tryParse(await _leer(txn, _folioAnio) ?? '');
        final ultimo = int.tryParse(await _leer(txn, _folioConsecutivo) ?? '');
        // El consecutivo se reinicia cada año (D-020).
        final siguiente =
            (anioGuardado == fecha.year && ultimo != null) ? ultimo + 1 : 1;
        await _escribir(txn, _folioAnio, '${fecha.year}');
        await _escribir(txn, _folioConsecutivo, '$siguiente');
        return 'BC-${fecha.year}-${siguiente.toString().padLeft(4, '0')}';
      });
    } catch (e) {
      throw AppException('No se pudo asignar el folio del reporte.', causa: e);
    }
  }

  // ---------------------------------------------------------------------

  Future<String?> _leer(DatabaseExecutor db, String clave) async {
    final filas = await db.query(AppDatabase.tablaAjustes,
        columns: ['valor'], where: 'clave = ?', whereArgs: [clave], limit: 1);
    return filas.isEmpty ? null : filas.first['valor'] as String;
  }

  Future<Map<String, String>> _leerVarios(
      DatabaseExecutor db, List<String> claves) async {
    final filas = await db.query(AppDatabase.tablaAjustes,
        where: 'clave IN (${List.filled(claves.length, '?').join(', ')})',
        whereArgs: claves);
    return {
      for (final f in filas) f['clave'] as String: f['valor'] as String,
    };
  }

  Future<void> _escribir(DatabaseExecutor db, String clave, String valor) =>
      db.insert(AppDatabase.tablaAjustes, {'clave': clave, 'valor': valor},
          conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> _escribirOBorrar(
      DatabaseExecutor db, String clave, String? valor) async {
    if (valor == null) {
      await db.delete(AppDatabase.tablaAjustes,
          where: 'clave = ?', whereArgs: [clave]);
    } else {
      await _escribir(db, clave, valor);
    }
  }
}
