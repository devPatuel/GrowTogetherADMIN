import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:growtogether_data/growtogether_data.dart';

import '../../../core/utils/formatters.dart';

/// Gráfico de barras con la serie "nuevos usuarios por mes" últimos N meses.
class NuevosUsuariosChart extends StatelessWidget {
  final List<NuevosUsuariosMes> datos;

  const NuevosUsuariosChart({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (datos.isEmpty) {
      return const Center(child: Text('Sin datos'));
    }
    final maxY = datos.map((e) => e.cantidad).fold<int>(0, (a, b) => a > b ? a : b);
    final maxYAjustado = (maxY < 5 ? 5 : (maxY * 1.2).ceil()).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxYAjustado,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colorScheme.outlineVariant,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= datos.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    Formatters.mesGrafico(datos[i].mes),
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(datos.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: datos[i].cantidad.toDouble(),
                color: colorScheme.primary,
                width: 22,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }
}
