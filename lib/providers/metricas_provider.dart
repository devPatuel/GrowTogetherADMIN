import 'package:flutter/foundation.dart';
import 'package:growtogether_data/growtogether_data.dart';

/// Estado de la pestaña de métricas. Solo se carga al entrar.
class MetricasProvider extends ChangeNotifier {
  final AdminRepository _repo;

  MetricasProvider(this._repo);

  bool _cargando = false;
  String? _error;
  MetricasAdmin? _metricas;

  bool get cargando => _cargando;
  String? get error => _error;
  MetricasAdmin? get metricas => _metricas;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _metricas = await _repo.obtenerMetricas();
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
