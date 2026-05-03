import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:growtogether_data/growtogether_data.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/snack_helper.dart';
import '../../providers/consejos_provider.dart';
import 'widgets/consejo_form_dialog.dart';

/// Pestaña de consejos con dos vistas: lista (tabla) y calendario mensual.
class ConsejosScreen extends StatefulWidget {
  const ConsejosScreen({super.key});

  @override
  State<ConsejosScreen> createState() => _ConsejosScreenState();
}

class _ConsejosScreenState extends State<ConsejosScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _yaCargado = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_yaCargado) {
      _yaCargado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ConsejosProvider>().cargar();
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final estado = context.read<ConsejosProvider>();
    final res = await showDialog<ConsejoFormResultado>(
      context: context,
      builder: (_) => ConsejoFormDialog(fechasOcupadas: estado.fechasOcupadas),
    );
    if (res == null || !mounted) return;
    final ok = await estado.crear(
      titulo: res.titulo,
      descripcion: res.descripcion,
      fechaPublicacion: res.fechaPublicacion,
      activo: res.activo,
    );
    if (!mounted) return;
    if (ok) {
      context.showSnackSuccess('Consejo creado');
    } else {
      context.showSnackError(estado.error ?? 'Error');
    }
  }

  Future<void> _editar(Consejo c) async {
    final estado = context.read<ConsejosProvider>();
    final res = await showDialog<ConsejoFormResultado>(
      context: context,
      builder: (_) => ConsejoFormDialog(consejo: c, fechasOcupadas: estado.fechasOcupadas),
    );
    if (res == null || !mounted) return;
    final ok = await estado.editar(
      c.id,
      titulo: res.titulo,
      descripcion: res.descripcion,
      fechaPublicacion: res.fechaPublicacion,
      activo: res.activo,
    );
    if (!mounted) return;
    if (ok) {
      context.showSnackSuccess('Consejo actualizado');
    } else {
      context.showSnackError(estado.error ?? 'Error');
    }
  }

  Future<void> _eliminar(Consejo c) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar consejo'),
        content: Text('¿Eliminar definitivamente el consejo "${c.titulo}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirma != true || !mounted) return;
    final estado = context.read<ConsejosProvider>();
    final ok = await estado.eliminar(c.id);
    if (!mounted) return;
    if (ok) {
      context.showSnackSuccess('Consejo eliminado');
    } else {
      context.showSnackError(estado.error ?? 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<ConsejosProvider>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabs,
                  tabs: const [
                    Tab(icon: Icon(Icons.list), text: 'Lista'),
                    Tab(icon: Icon(Icons.calendar_month), text: 'Calendario'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: _crear,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo consejo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: estado.cargando && estado.consejos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : (estado.error != null && estado.consejos.isEmpty)
                    ? _errorBox(estado)
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _ListaConsejos(
                            consejos: estado.consejos,
                            onEditar: _editar,
                            onEliminar: _eliminar,
                          ),
                          _CalendarioConsejos(
                            consejos: estado.consejos,
                            onEditar: _editar,
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(ConsejosProvider estado) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 32),
          const SizedBox(height: 8),
          Text(estado.error!),
          const SizedBox(height: 8),
          FilledButton(onPressed: () => estado.cargar(), child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _ListaConsejos extends StatelessWidget {
  final List<Consejo> consejos;
  final Future<void> Function(Consejo) onEditar;
  final Future<void> Function(Consejo) onEliminar;

  const _ListaConsejos({
    required this.consejos,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (consejos.isEmpty) {
      return const Center(child: Text('No hay consejos creados todavía'));
    }
    final ordenados = [...consejos];
    ordenados.sort((a, b) {
      final fa = a.fechaPublicacion;
      final fb = b.fechaPublicacion;
      if (fa == null && fb == null) return a.titulo.compareTo(b.titulo);
      if (fa == null) return 1;
      if (fb == null) return -1;
      return fa.compareTo(fb);
    });
    return Card(
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 16,
        minWidth: 800,
        headingRowColor: WidgetStateProperty.all(colorScheme.surfaceContainerLow),
        columns: const [
          DataColumn2(label: Text('Fecha'), fixedWidth: 120),
          DataColumn2(label: Text('Título'), size: ColumnSize.M),
          DataColumn2(label: Text('Descripción'), size: ColumnSize.L),
          DataColumn2(label: Text('Estado'), fixedWidth: 100),
          DataColumn2(label: Text('Acciones'), fixedWidth: 140),
        ],
        rows: ordenados.map((c) {
          return DataRow(cells: [
            DataCell(Text(Formatters.fecha(c.fechaPublicacion))),
            DataCell(Text(c.titulo, maxLines: 1, overflow: TextOverflow.ellipsis)),
            DataCell(Tooltip(
              message: c.descripcion,
              child: Text(c.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
            )),
            DataCell(Chip(
              label: Text(c.activo ? 'Activo' : 'Inactivo'),
              backgroundColor: c.activo
                  ? Colors.green.shade100
                  : colorScheme.surfaceContainerHighest,
              labelStyle: TextStyle(
                color: c.activo ? Colors.green.shade900 : colorScheme.onSurfaceVariant,
              ),
              side: BorderSide.none,
            )),
            DataCell(Row(
              children: [
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => onEditar(c),
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                  onPressed: () => onEliminar(c),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }
}

/// Vista calendario mensual: una celda por día del mes con el consejo asignado
/// (si existe). Permite navegar entre meses.
class _CalendarioConsejos extends StatefulWidget {
  final List<Consejo> consejos;
  final Future<void> Function(Consejo) onEditar;

  const _CalendarioConsejos({required this.consejos, required this.onEditar});

  @override
  State<_CalendarioConsejos> createState() => _CalendarioConsejosState();
}

class _CalendarioConsejosState extends State<_CalendarioConsejos> {
  late DateTime _mesVisible;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _mesVisible = DateTime(hoy.year, hoy.month, 1);
  }

  Map<DateTime, Consejo> get _porFecha {
    final mapa = <DateTime, Consejo>{};
    for (final c in widget.consejos) {
      final f = c.fechaPublicacion;
      if (f == null) continue;
      mapa[DateTime(f.year, f.month, f.day)] = c;
    }
    return mapa;
  }

  void _cambiarMes(int delta) {
    setState(() {
      _mesVisible = DateTime(_mesVisible.year, _mesVisible.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final porFecha = _porFecha;
    final inicio = DateTime(_mesVisible.year, _mesVisible.month, 1);
    final diasMes = DateTime(_mesVisible.year, _mesVisible.month + 1, 0).day;
    final desfase = (inicio.weekday - 1) % 7; // lunes = 0
    final celdas = desfase + diasMes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _cambiarMes(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                const SizedBox(width: 8),
                Text(
                  Formatters.mesGrafico('${_mesVisible.year}-${_mesVisible.month.toString().padLeft(2, '0')}'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: () => _cambiarMes(1),
                  icon: const Icon(Icons.chevron_right),
                ),
                const Spacer(),
                Text(
                  '${porFecha.length} consejos con fecha en total',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                  .map((d) => Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(d,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurfaceVariant)),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.0,
                ),
                itemCount: celdas,
                itemBuilder: (ctx, i) {
                  if (i < desfase) return const SizedBox.shrink();
                  final dia = i - desfase + 1;
                  final fecha = DateTime(_mesVisible.year, _mesVisible.month, dia);
                  final consejo = porFecha[fecha];
                  return _CeldaDia(dia: dia, consejo: consejo, onTap: consejo == null ? null : () => widget.onEditar(consejo));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CeldaDia extends StatelessWidget {
  final int dia;
  final Consejo? consejo;
  final VoidCallback? onTap;

  const _CeldaDia({required this.dia, this.consejo, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tieneConsejo = consejo != null;
    return Material(
      color: tieneConsejo
          ? (consejo!.activo ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest)
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$dia',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: tieneConsejo ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                ),
              ),
              if (tieneConsejo)
                Expanded(
                  child: Text(
                    consejo!.titulo,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
