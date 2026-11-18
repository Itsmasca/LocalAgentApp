import 'package:flutter/material.dart';

import '../../domain/entities/responsable.dart';
import '../../domain/repositories/ajustes_repository.dart';
import 'estado_vista.dart';

/// Diálogo para capturar o editar los datos del responsable
/// (contracts/flujo-ui.md §3). Devuelve el responsable guardado, o `null`
/// si el usuario eligió "Omitir".
Future<Responsable?> mostrarDialogoResponsable(
  BuildContext context, {
  required AjustesRepository ajustes,
  Responsable? actual,
}) {
  return showDialog<Responsable>(
    context: context,
    builder: (_) => _DialogoResponsable(ajustes: ajustes, actual: actual),
  );
}

class _DialogoResponsable extends StatefulWidget {
  final AjustesRepository ajustes;
  final Responsable? actual;

  const _DialogoResponsable({required this.ajustes, this.actual});

  @override
  State<_DialogoResponsable> createState() => _DialogoResponsableState();
}

class _DialogoResponsableState extends State<_DialogoResponsable> {
  late final _nombre = TextEditingController(text: widget.actual?.nombre);
  late final _negocio = TextEditingController(text: widget.actual?.negocio);
  late final _telefono = TextEditingController(text: widget.actual?.telefono);
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombre.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombre.dispose();
    _negocio.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final r = Responsable(
        nombre: _nombre.text,
        negocio: _negocio.text,
        telefono: _telefono.text,
      );
      await widget.ajustes.guardarResponsable(r);
      if (mounted) Navigator.pop(context, r);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tus datos para los reportes'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombre,
              maxLength: Responsable.maxNombre,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre *'),
            ),
            TextField(
              controller: _negocio,
              maxLength: Responsable.maxNegocio,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Negocio'),
            ),
            TextField(
              controller: _telefono,
              maxLength: Responsable.maxTelefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Omitir'),
        ),
        FilledButton(
          onPressed: _guardando || _nombre.text.trim().isEmpty ? null : _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
