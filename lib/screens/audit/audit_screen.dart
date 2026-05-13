import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../providers/audit_provider.dart';

/// Pestaña de auditoría con filtros (admin, entidad, acción, rango fechas)
/// y tabla con scroll.
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
              child: estado.cargando && estado.logs.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : (estado.error != null && estado.logs.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, color: colorScheme.error, size: 32),
                              const SizedBox(height: 8),
                              Text(estado.error!),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: () => estado.cargar(),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : DataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 16,
                          minWidth: 1000,
                          headingRowColor: WidgetStateProperty.all(colorScheme.surfaceContainerLow),
                          columns: const [
                            DataColumn2(label: Text('Fecha'), fixedWidth: 160),
                            DataColumn2(label: Text('Admin'), size: ColumnSize.M),
                            DataColumn2(label: Text('Acción'), fixedWidth: 130),
                            DataColumn2(label: Text('Entidad'), fixedWidth: 110),
                            DataColumn2(label: Text('ID'), fixedWidth: 70),
                            DataColumn2(label: Text('Detalle'), size: ColumnSize.L),
                            DataColumn2(label: Text('IP'), fixedWidth: 130),
                          ],
                          rows: estado.logs.map(_filaLog).toList(),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _filaLog(dynamic l) {
    return DataRow(cells: [
      DataCell(Text(Formatters.fechaHora(l.fecha))),
      DataCell(Text(l.usuarioEmail ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis)),
      DataCell(Text(l.accion)),
      DataCell(Text(l.entidad)),
      DataCell(Text(l.entidadId?.toString() ?? '—')),
      DataCell(Tooltip(
        message: l.detalle ?? '',
        child: Text(l.detalle ?? '—', maxLines: 2, overflow: TextOverflow.ellipsis),
      )),
      DataCell(Text(l.ip ?? '—')),
    ]);
  }

  Widget _filtroDropdown({
    required String hint,
    required String? valor,
    required List<String> opciones,
    required ValueChanged<String?> onChanged,
  }) {
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
