import 'package:flutter/foundation.dart';
import 'package:growtogether_data/growtogether_data.dart';

/// Estado de la pestaña de audit log. Mantiene la lista descargada y los
/// filtros aplicados en cliente (admin, entidad, acción y rango fechas).
class AuditProvider extends ChangeNotifier {
  final AdminRepository _repo;

  AuditProvider(this._repo);

  bool _cargando = false;
  String? _error;
  List<AuditLog> _logs = [];

  String _filtroAdmin = '';
  String _filtroEntidad = '';
  String _filtroAccion = '';
  DateTime? _desde;
  DateTime? _hasta;

  bool get cargando => _cargando;
  String? get error => _error;
  String get filtroAdmin => _filtroAdmin;
  String get filtroEntidad => _filtroEntidad;
  String get filtroAccion => _filtroAccion;
  DateTime? get desde => _desde;
  DateTime? get hasta => _hasta;

  /// Lista filtrada en cliente (los filtros son baratos, ≤100 entradas).
  List<AuditLog> get logs {
    final qAdmin = _filtroAdmin.toLowerCase();
    final qEntidad = _filtroEntidad.toLowerCase();
    final qAccion = _filtroAccion.toLowerCase();
    return _logs.where((l) {
      if (qAdmin.isNotEmpty &&
          !(l.usuarioEmail ?? '').toLowerCase().contains(qAdmin)) {
        return false;
      }
      if (qEntidad.isNotEmpty &&
          !l.entidad.toLowerCase().contains(qEntidad)) {
        return false;
      }
      if (qAccion.isNotEmpty &&
          !l.accion.toLowerCase().contains(qAccion)) {
        return false;
      }
      if (_desde != null && l.fecha.isBefore(_desde!)) return false;
      if (_hasta != null && l.fecha.isAfter(_hasta!)) return false;
      return true;
    }).toList();
  }

  /// Conjuntos para alimentar los selectores de filtro.
  List<String> get adminsDisponibles =>
      _logs.map((l) => l.usuarioEmail ?? '').where((s) => s.isNotEmpty).toSet().toList()..sort();
  List<String> get entidadesDisponibles =>
      _logs.map((l) => l.entidad).toSet().toList()..sort();
  List<String> get accionesDisponibles =>
      _logs.map((l) => l.accion).toSet().toList()..sort();

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _logs = await _repo.listarAuditLog();
      debugPrint('[AuditProvider] cargar() OK - ${_logs.length} registros recibidos');
    } catch (e, stack) {
      _error = e.toString();
      debugPrint('[AuditProvider] cargar() ERROR: $e');
      debugPrint('$stack');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void setFiltroAdmin(String v) { _filtroAdmin = v; notifyListeners(); }
  void setFiltroEntidad(String v) { _filtroEntidad = v; notifyListeners(); }
  void setFiltroAccion(String v) { _filtroAccion = v; notifyListeners(); }
  void setRango(DateTime? d, DateTime? h) { _desde = d; _hasta = h; notifyListeners(); }

  void limpiarFiltros() {
    _filtroAdmin = '';
    _filtroEntidad = '';
    _filtroAccion = '';
    _desde = null;
    _hasta = null;
    notifyListeners();
  }
}
