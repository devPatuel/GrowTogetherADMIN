import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../providers/metricas_provider.dart';
import 'widgets/metric_card.dart';
import 'widgets/nuevos_chart.dart';

/// Dashboard de métricas globales del panel admin.
class MetricasScreen extends StatefulWidget {
  const MetricasScreen({super.key});

  @override
  State<MetricasScreen> createState() => _MetricasScreenState();
}

class _MetricasScreenState extends State<MetricasScreen> {
  bool _yaCargado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_yaCargado) {
      _yaCargado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<MetricasProvider>().cargar();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<MetricasProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (estado.cargando && estado.metricas == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (estado.error != null && estado.metricas == null) {
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

    final m = estado.metricas!;
    final veterano = m.usuarioMasVeterano;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Resumen general',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _wrapCard(MetricCard(
                icono: Icons.people_outline,
                etiqueta: 'Usuarios activos',
                valor: '${m.usuariosActivos}',
              )),
              _wrapCard(MetricCard(
                icono: Icons.group,
                etiqueta: 'Total de usuarios',
                valor: '${m.totalUsuarios}',
                color: Colors.blue,
              )),
              _wrapCard(MetricCard(
                icono: Icons.checklist_rtl,
                etiqueta: 'Hábitos creados',
                valor: '${m.totalHabitos}',
                color: Colors.deepPurple,
              )),
              _wrapCard(MetricCard(
                icono: Icons.task_alt,
                etiqueta: 'Hábitos completados hoy',
                valor: '${m.habitosCompletadosHoy}',
                color: Colors.teal,
              )),
              _wrapCard(MetricCard(
                icono: Icons.flag_outlined,
                etiqueta: 'Desafíos activos',
                valor: '${m.desafiosActivos}',
                color: Colors.orange,
              )),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 640,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nuevos usuarios por mes',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 240,
                          child: NuevosUsuariosChart(datos: m.usuariosNuevosPorMes),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 320,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Usuario más veterano',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        if (veterano == null)
                          const Text('Sin usuarios activos todavía')
                        else ...[
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              veterano.nombre.isNotEmpty ? veterano.nombre[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(veterano.nombre,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          Text(veterano.email,
                              style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          Text('Desde ${Formatters.fecha(veterano.fechaRegistro)}',
                              style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _wrapCard(Widget card) => SizedBox(width: 280, child: card);
}
