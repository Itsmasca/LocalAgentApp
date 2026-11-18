import 'package:sqflite/sqflite.dart';

import '../../domain/entities/entrada.dart';
import '../db/app_database.dart';

/// Traduce entre la entidad [Entrada] y sus filas de SQLite
/// (una en `entradas` y una por foto en `fotos`).
class EntradaModel {
  static Entrada fromMap(Map<String, Object?> m,
          {List<String> fotos = const []}) =>
      Entrada(
        id: m['id'] as int,
        ubicacionId: m['ubicacion_id'] as int,
        texto: m['texto'] as String,
        fotos: fotos,
        latitud: (m['latitud'] as num).toDouble(),
        longitud: (m['longitud'] as num).toDouble(),
        creadaEn: DateTime.parse(m['creada_en'] as String),
      );

  /// Fila de `entradas` (sin fotos; ver [insertarFotos]).
  static Map<String, Object?> toMap(Entrada e) => {
        if (e.id != null) 'id': e.id,
        'ubicacion_id': e.ubicacionId,
        'texto': e.texto,
        'latitud': e.latitud,
        'longitud': e.longitud,
        'creada_en': e.creadaEn.toIso8601String(),
      };

  /// Inserta las fotos de una entrada ya guardada, conservando su orden.
  static Future<void> insertarFotos(
      DatabaseExecutor db, int entradaId, List<String> fotos) async {
    for (var i = 0; i < fotos.length; i++) {
      await db.insert(AppDatabase.tablaFotos,
          {'entrada_id': entradaId, 'ruta': fotos[i], 'orden': i});
    }
  }
}
