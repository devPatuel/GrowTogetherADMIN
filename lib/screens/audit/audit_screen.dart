import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../providers/audit_provider.dart';

/// Pestaña de auditoría con filtros (admin, entidad, acción, rango fechas)
/// y tabla con scroll horizontal y vertical.
class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  bool _yaCargado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_yaCargado) {
      _yaCargado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AuditProvider>().cargar();
      });
    }
  }

  Future<void> _elegirRango(AuditProvider estado) async {
    final hoy = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(hoy.year - 2),
      lastDate: DateTime(hoy.year + 1),
      initialDateRange: estado.desde != null && estado.hasta != null
          ? DateTimeRange(start: estado.desde!, end: estado.hasta!)
          : null,
    );
    if (rango != null) {
      estado.setRango(rango.start, rango.end.add(const Duration(hours: 23, minutes: 59)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AuditProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: _filtroDropdown(
                  hint: 'Admin',
                  valor: estado.filtroAdmin.isEmpty ? null : estado.filtroAdmin,
                  opciones: estado.adminsDisponibles,
                  onChanged: (v) => estado.setFiltroAdmin(v ?? ''),
                ),
              ),
              SizedBox(
                width: 180,
                child: _filtroDropdown(
                  hint: 'Entidad',
                  valor: estado.filtroEntidad.isEmpty ? null : estado.filtroEntidad,
                  opciones: estado.entidadesDisponibles,
                  onChanged: (v) => estado.setFiltroEntidad(v ?? ''),
                ),
              ),
              SizedBox(
                width: 180,
                child: _filtroDropdown(
                  hint: 'Acción',
                  valor: estado.filtroAccion.isEmpty ? null : estado.filtroAccion,
                  opciones: estado.accionesDisponibles,
                  onChanged: (v) => estado.setFiltroAccion(v ?? ''),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _elegirRango(estado),
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(estado.desde == null
                    ? 'Rango fechas'
                    : '${Formatters.fecha(estado.desde)} – ${Formatters.fecha(estado.hasta)}'),
              ),
              TextButton.icon(
                onPressed: estado.limpiarFiltros,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Limpiar'),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: estado.cargando ? null : () => estado.cargar(),
                icon: const Icon(Icons.refresh),
                label: const Text('Refrescar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: _buildContenido(estado, colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido(AuditProvider estado, ColorScheme colorScheme) {
    if (estado.cargando && estado.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (estado.error != null && estado.logs.isEmpty) {
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
    if (estado.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off, color: colorScheme.outline, size: 48),
            const SizedBox(height: 12),
            Text(
              'No hay registros con los filtros aplicados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }
    return _buildTabla(estado, colorScheme);
  }

  Widget _buildTabla(AuditProvider estado, ColorScheme colorScheme) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 18,
            horizontalMargin: 16,
            headingRowColor: WidgetStateProperty.all(colorScheme.surfaceContainerLow),
            columns: const [
              DataColumn(label: Text('Fecha')),
              DataColumn(label: Text('Admin')),
              DataColumn(label: Text('Acción')),
              DataColumn(label: Text('Entidad')),
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Detalle')),
              DataColumn(label: Text('IP')),
            ],
            rows: estado.logs.map((l) {
              return DataRow(cells: [
                DataCell(Text(Formatters.fechaHora(l.fecha))),
                DataCell(SizedBox(
                  width: 200,
                  child: Text(l.usuarioEmail ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
                DataCell(Text(l.accion)),
                DataCell(Text(l.entidad)),
                DataCell(Text(l.entidadId?.toString() ?? '—')),
                DataCell(SizedBox(
                  width: 320,
                  child: Tooltip(
                    message: l.detalle ?? '',
                    child: Text(l.detalle ?? '—', maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                )),
                DataCell(Text(l.ip ?? '—')),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _filtroDropdown({
    required String hint,
    required String? valor,
    required List<String> opciones,
    required ValueChanged<String?> onChanged,
  }) {
    // Filtrar opciones vacías para evitar colisión con el item 'Todos' (value='').
    final opcionesLimpias = opciones.where((o) => o.isNotEmpty).toSet().toList();
    return DropdownButtonFormField<String>(
      initialValue: valor,
      isExpanded: true,
      decoration: InputDecoration(labelText: hint),
      items: [
        const DropdownMenuItem(value: '', child: Text('Todos')),
        ...opcionesLimpias.map((o) => DropdownMenuItem(
              value: o,
              child: Text(o, overflow: TextOverflow.ellipsis, maxLines: 1),
            )),
      ],
      onChanged: onChanged,
    );
  }
}
