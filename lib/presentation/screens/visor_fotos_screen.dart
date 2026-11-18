import 'package:flutter/material.dart';

import '../widgets/foto_local.dart';

/// Argumentos de la ruta `/fotos`.
class VisorFotosArgs {
  final List<String> fotos;
  final int inicial;
  const VisorFotosArgs(this.fotos, this.inicial);
}

/// Fotos de una entrada a pantalla completa, con zoom (spec 004, FR-011).
class VisorFotosScreen extends StatefulWidget {
  final VisorFotosArgs args;

  const VisorFotosScreen({super.key, required this.args});

  @override
  State<VisorFotosScreen> createState() => _VisorFotosScreenState();
}

class _VisorFotosScreenState extends State<VisorFotosScreen> {
  late final PageController _paginas =
      PageController(initialPage: widget.args.inicial);
  late int _actual = widget.args.inicial;

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fotos = widget.args.fotos;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${_actual + 1}/${fotos.length}'),
      ),
      body: PageView.builder(
        controller: _paginas,
        itemCount: fotos.length,
        onPageChanged: (i) => setState(() => _actual = i),
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: FotoLocal(
              ruta: fotos[i],
              ancho: double.infinity,
              borde: BorderRadius.zero,
            ),
          ),
        ),
      ),
    );
  }
}
