import 'package:intl/intl.dart';

/// Formateadores comunes para fechas y datos del panel.
class Formatters {
  Formatters._();

  static final DateFormat _fechaCorta = DateFormat('dd/MM/yyyy', 'es_ES');
  static final DateFormat _fechaHora = DateFormat('dd/MM/yyyy HH:mm', 'es_ES');
  static final DateFormat _mesAno = DateFormat('MMM yyyy', 'es_ES');

  static String fecha(DateTime? f) => f == null ? '—' : _fechaCorta.format(f);
  static String fechaHora(DateTime? f) => f == null ? '—' : _fechaHora.format(f);

  /// Convierte "YYYY-MM" a "MMM yyyy" para etiquetas de gráficos.
  static String mesGrafico(String yyyymm) {
    final partes = yyyymm.split('-');
    if (partes.length != 2) return yyyymm;
    final anio = int.tryParse(partes[0]) ?? 1970;
    final mes = int.tryParse(partes[1]) ?? 1;
    return _mesAno.format(DateTime(anio, mes));
  }
}
