import 'package:flutter/material.dart';

import 'foto_local.dart';

/// Fotos de una entrada en primer plano, sin deslizar (spec 004, D-028):
/// - 1 foto: todo el ancho, 4:3.
/// - 2 fotos: lado a lado.
/// - 3 fotos: una grande a la izquierda y dos apiladas.
/// - 4 o más: cuadrícula 2×2; la cuarta celda indica "+N" fotos más.
class MosaicoFotos extends StatelessWidget {
  final List<String> fotos;
  final void Function(int indice) onTocar;

  const MosaicoFotos({super.key, required this.fotos, required this.onTocar});

  static const _espacio = 2.0;

  @override
  Widget build(BuildContext context) {
    if (fotos.isEmpty) return const SizedBox.shrink();
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      Widget celda(int i, double anchoCelda, {int? extra}) => _Celda(
            ruta: fotos[i],
            cacheWidth: (anchoCelda * dpr).round(),
            extra: extra,
            onTap: () => onTocar(i),
          );

      switch (fotos.length) {
        case 1:
          return SizedBox(height: w * 3 / 4, child: celda(0, w));
        case 2:
          final mitad = (w - _espacio) / 2;
          return SizedBox(
            height: mitad,
            child: Row(children: [
              Expanded(child: celda(0, mitad)),
              const SizedBox(width: _espacio),
              Expanded(child: celda(1, mitad)),
            ]),
          );
        case 3:
          final alto = w * 2 / 3;
          return SizedBox(
            height: alto,
            child: Row(children: [
              Expanded(flex: 2, child: celda(0, w * 2 / 3)),
              const SizedBox(width: _espacio),
              Expanded(
                child: Column(children: [
                  Expanded(child: celda(1, w / 3)),
                  const SizedBox(height: _espacio),
                  Expanded(child: celda(2, w / 3)),
                ]),
              ),
            ]),
          );
        default:
          final mitad = (w - _espacio) / 2;
          final resto = fotos.length - 4;
          Widget fila(int a, int b, {int? extra}) => Expanded(
                child: Row(children: [
                  Expanded(child: celda(a, mitad)),
                  const SizedBox(width: _espacio),
                  Expanded(child: celda(b, mitad, extra: extra)),
                ]),
              );
          return SizedBox(
            height: w,
            child: Column(children: [
              fila(0, 1),
              const SizedBox(height: _espacio),
              fila(2, 3, extra: resto > 0 ? resto + 1 : null),
            ]),
          );
      }
    });
  }
}

class _Celda extends StatelessWidget {
  final String ruta;
  final int cacheWidth;
  final int? extra;
  final VoidCallback onTap;

  const _Celda({
    required this.ruta,
    required this.cacheWidth,
    required this.extra,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FotoLocal(
            ruta: ruta,
            ancho: double.infinity,
            alto: double.infinity,
            borde: BorderRadius.zero,
            cacheWidth: cacheWidth,
          ),
          if (extra != null)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Text(
                '+$extra',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
