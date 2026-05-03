import 'package:flutter/foundation.dart';
import 'package:growtogether_data/growtogether_data.dart';

/// Estado y operaciones de la pestaña de consejos del panel.
///
/// Mantiene la lista en memoria y expone helpers para saber qué fechas están
/// ocupadas (usado por el date picker para deshabilitar días con consejo).
class ConsejosProvider extends ChangeNotifier {
  final AdminRepository _repo;

  ConsejosProvider(this._repo);

  bool _cargando = false;
  String? _error;
  List<Consejo> _consejos = [];

  bool get cargando => _cargando;
  String? get error => _error;
  List<Consejo> get consejos => List.unmodifiable(_consejos);

  /// Set de fechas ocupadas (sin tener en cuenta la hora) para validar
  /// rápidamente desde el date picker.
  Set<DateTime> get fechasOcupadas {
    return _consejos
        .where((c) => c.fechaPublicacion != null)
        .map((c) => DateTime(
              c.fechaPublicacion!.year,
              c.fechaPublicacion!.month,
              c.fechaPublicacion!.day,
            ))
        .toSet();
  }

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _consejos = await _repo.listarConsejos();
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> crear({
    required String titulo,
    required String descripcion,
    DateTime? fechaPublicacion,
    bool activo = true,
  }) async {
    try {
      await _repo.crearConsejo(
        titulo: titulo,
        descripcion: descripcion,
        fechaPublicacion: fechaPublicacion,
        activo: activo,
      );
      await cargar();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> editar(
    int id, {
    required String titulo,
    required String descripcion,
    DateTime? fechaPublicacion,
    required bool activo,
  }) async {
    try {
      await _repo.editarConsejo(
        id,
        titulo: titulo,
        descripcion: descripcion,
        fechaPublicacion: fechaPublicacion,
        activo: activo,
      );
      await cargar();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminar(int id) async {
    try {
      await _repo.eliminarConsejo(id);
      await cargar();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
