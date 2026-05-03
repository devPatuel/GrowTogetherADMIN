import 'package:flutter/material.dart';

/// Diálogo modal para introducir el motivo de bloqueo de un usuario.
/// Devuelve el motivo introducido (no vacío, ≤500 caracteres) o null si se cancela.
class BloquearDialog extends StatefulWidget {
  final String nombreUsuario;

  const BloquearDialog({super.key, required this.nombreUsuario});

  @override
  State<BloquearDialog> createState() => _BloquearDialogState();
}

class _BloquearDialogState extends State<BloquearDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Bloquear a ${widget.nombreUsuario}'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Indica el motivo del bloqueo. Quedará registrado en el audit log.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ctrl,
                maxLength: 500,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Motivo',
                  hintText: 'Ejemplo: comportamiento inapropiado en la comunidad',
                ),
                validator: (v) {
                  final texto = v?.trim() ?? '';
                  if (texto.isEmpty) return 'El motivo es obligatorio';
                  if (texto.length > 500) return 'Máximo 500 caracteres';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirmar,
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Bloquear'),
        ),
      ],
    );
  }
}
