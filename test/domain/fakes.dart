import 'package:bitacora_campo/domain/entities/entrada.dart';
import 'package:bitacora_campo/domain/entities/observacion.dart';
import 'package:bitacora_campo/domain/entities/visita.dart';
import 'package:bitacora_campo/domain/repositories/observacion_repository.dart';
import 'package:bitacora_campo/domain/entities/paquete_evidencia.dart';
import 'package:bitacora_campo/domain/entities/reporte_generado.dart';
import 'package:bitacora_campo/domain/entities/responsable.dart';
import 'package:bitacora_campo/domain/entities/ubicacion.dart';
import 'package:bitacora_campo/domain/repositories/ajustes_repository.dart';
import 'package:bitacora_campo/domain/repositories/entrada_repository.dart';
import 'package:bitacora_campo/domain/services/almacen_fotos.dart';
import 'package:bitacora_campo/domain/services/compartir_service.dart';
import 'package:bitacora_campo/domain/services/generador_reporte.dart';

/// Dobles en memoria de las interfaces del dominio. Registran las llamadas
/// para que las pruebas puedan verificarlas.

final casa = Ubicacion(
  id: 1,
  nombre: 'Casa Sra. López',
  latitud: 19.4326,
  longitud: -99.1332,
  creadaEn: DateTime(2026, 11, 1),
);

Entrada entrada(int id, DateTime creadaEn,
        {String texto = '', List<String> fotos = const []}) =>
    Entrada(
      id: id,
      ubicacionId: casa.id!,
      texto: texto,
      fotos: fotos,
      latitud: casa.latitud,
      longitud: casa.longitud,
      creadaEn: creadaEn,
    );

class FakeEntradaRepository implements EntradaRepository {
  final List<Entrada> entradas;
  final List<Observacion> observaciones;
  FakeEntradaRepository(this.entradas, {this.observaciones = const []});

  List<Entrada> _delLugar(int ubicacionId) =>
      entradas.where((e) => e.ubicacionId == ubicacionId).toList()
        ..sort((a, b) => a.creadaEn.compareTo(b.creadaEn));

  @override
  Future<List<Entrada>> obtenerPorUbicacion(int ubicacionId) async =>
      entradas.where((e) => e.ubicacionId == ubicacionId).toList();

  @override
  Future<Entrada> crear(Entrada entrada) async => entrada;

  @override
  Future<List<Visita>> obtenerVisitas(int ubicacionId) async => [
        for (final e in _delLugar(ubicacionId))
          Visita(
            entrada: e,
            observaciones:
                observaciones.where((o) => o.entradaId == e.id).toList(),
          ),
      ];

  @override
  Future<Entrada?> obtenerMasReciente(int ubicacionId) async {
    final lista = _delLugar(ubicacionId);
    return lista.isEmpty ? null : lista.last;
  }
}

class FakeObservacionRepository implements ObservacionRepository {
  final List<Observacion> guardadas = [];
  final List<int> eliminadas = [];

  @override
  Future<Observacion> crear(Observacion observacion) async {
    final o = observacion.copyWith(id: guardadas.length + 1);
    guardadas.add(o);
    return o;
  }

  @override
  Future<void> eliminar(int id) async => eliminadas.add(id);
}

class FakeAjustesRepository implements AjustesRepository {
  Responsable? responsable;
  bool coordenadas;
  int folios = 0;
  final List<bool> coordenadasGuardadas = [];

  FakeAjustesRepository({this.responsable, this.coordenadas = true});

  @override
  Future<Responsable?> obtenerResponsable() async => responsable;

  @override
  Future<void> guardarResponsable(Responsable r) async => responsable = r;

  @override
  Future<void> borrarResponsable() async => responsable = null;

  @override
  Future<bool> incluirCoordenadas() async => coordenadas;

  @override
  Future<void> guardarIncluirCoordenadas(bool valor) async {
    coordenadas = valor;
    coordenadasGuardadas.add(valor);
  }

  @override
  Future<String> reservarFolio(DateTime fecha) async =>
      'BC-${fecha.year}-${(++folios).toString().padLeft(4, '0')}';
}

class FakeAlmacenFotos implements AlmacenFotos {
  final Set<String> faltantes;
  FakeAlmacenFotos({this.faltantes = const {}});

  @override
  Future<bool> existe(String ruta) async => !faltantes.contains(ruta);
}

class FakeGeneradorReporte implements GeneradorReporte {
  final List<(PaqueteEvidencia, String)> llamadas = [];

  @override
  Future<ReporteGenerado> generar(PaqueteEvidencia paquete, String folio,
      {void Function(double progreso)? onProgreso}) async {
    llamadas.add((paquete, folio));
    onProgreso?.call(1);
    return ReporteGenerado(
        folio: folio, rutaArchivo: '/tmp/compartir/$folio.pdf', fotosOmitidas: 0);
  }
}

class FakeCompartirService implements CompartirService {
  ResultadoCompartir resultado;
  final List<String> eventos = [];
  final List<(String, String?)> archivos = [];
  final List<(String, List<String>)> mensajes = [];

  FakeCompartirService({this.resultado = ResultadoCompartir.enviado});

  @override
  Future<ResultadoCompartir> compartirArchivo(String ruta,
      {String? asunto}) async {
    eventos.add('archivo');
    archivos.add((ruta, asunto));
    return resultado;
  }

  @override
  Future<ResultadoCompartir> compartirMensaje(
      String texto, List<String> fotos) async {
    eventos.add('mensaje');
    mensajes.add((texto, fotos));
    return resultado;
  }

  @override
  Future<void> limpiarTemporales() async => eventos.add('limpiar');

  @override
  Future<String> guardarEnDispositivo(String ruta) async {
    eventos.add('guardar');
    return '/docs/reportes/${ruta.split('/').last}';
  }
}
