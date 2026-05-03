import 'package:flutter/material.dart';
import 'package:growtogether_data/growtogether_data.dart';

/// Resultado del formulario de consejo: o bien los datos a guardar, o null
/// si el usuario cancela. La fecha es opcional.
class ConsejoFormResultado {
  final String titulo;
  final String descripcion;
  final DateTime? fechaPublicacion;
  final bool activo;

  ConsejoFormResultado({
    required this.titulo,
    required this.descripcion,
    required this.fechaPublicacion,
    required this.activo,
  });
}

/// Diálogo de creación/edición de un consejo. Recibe el conjunto de fechas
/// ya ocupadas por otros consejos para deshabilitarlas en el date picker.
class ConsejoFormDialog extends StatefulWidget {
  /// Consejo a editar, o null si es creación.
  final Consejo? consejo;
  final Set<DateTime> fechasOcupadas;

  const ConsejoFormDialog({
    super.key,
    this.consejo,
    this.fechasOcupadas = const {},
  });

  @override
  State<ConsejoFormDialog> createState() => _ConsejoFormDialogState();
}

class _ConsejoFormDialogState extends State<ConsejoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descCtrl;
  DateTime? _fecha;
  bool _activo = true;

  bool get _esEdicion => widget.consejo != null;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.consejo?.titulo ?? '');
    _descCtrl = TextEditingController(text: widget.consejo?.descripcion ?? '');
    _fecha = widget.consejo?.fechaPublicacion;
    _activo = widget.consejo?.activo ?? true;
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool _fechaOcupada(DateTime d) {
    final propia = widget.consejo?.fechaPublicacion;
    final dia = DateTime(d.year, d.month, d.day);
    if (propia != null &&
        DateTime(propia.year, propia.month, propia.day) == dia) {
      return false;
    }
    return widget.fechasOcupadas.contains(dia);
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final inicial = _fecha ?? hoy;
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaOcupada(inicial) ? hoy : inicial,
      firstDate: DateTime(hoy.year - 1),
      lastDate: DateTime(hoy.year + 5),
      selectableDayPredicate: (d) => !_fechaOcupada(d),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  void _guardar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(ConsejoFormResultado(
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descCtrl.text.trim(),
      fechaPublicacion: _fecha,
      activo: _activo,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Editar consejo' : 'Nuevo consejo'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _tituloCtrl,
                  maxLength: 200,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.length < 2) return 'Mínimo 2 caracteres';
                    if (t.length > 200) return 'Máximo 200 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLength: 5000,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'La descripción no puede estar vacía';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Fecha de publicación'),
                        child: Text(_fecha == null
                            ? 'Sin asignar'
                            : '${_fecha!.day.toString().padLeft(2, '0')}/${_fecha!.month.toString().padLeft(2, '0')}/${_fecha!.year}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: _elegirFecha,
                      icon: const Icon(Icons.calendar_today, size: 18),
                    ),
                    if (_fecha != null)
                      IconButton(
                        tooltip: 'Quitar fecha',
                        onPressed: () => setState(() => _fecha = null),
                        icon: const Icon(Icons.clear, size: 18),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _activo,
                  title: const Text('Activo'),
                  subtitle: const Text('Solo los consejos activos se muestran a los usuarios'),
                  onChanged: (v) => setState(() => _activo = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: Text(_esEdicion ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
