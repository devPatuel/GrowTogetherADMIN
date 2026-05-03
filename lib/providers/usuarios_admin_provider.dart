import 'package:flutter/foundation.dart';
import 'package:growtogether_data/growtogether_data.dart';

/// Estado y operaciones de la pestaña de usuarios del panel.
///
/// Mantiene la lista en memoria y aplica filtros de búsqueda en cliente.
/// Las acciones (bloquear/desbloquear/crear admin) refrescan la lista al terminar.
class UsuariosAdminProvider extends ChangeNotifier {
  final AdminRepository _repo;

  UsuariosAdminProvider(this._repo);

  bool _cargando = false;
  String? _error;
  List<UsuarioAdmin> _usuarios = [];
  String _busqueda = '';

  bool get cargando => _cargando;
  String? get error => _error;
  String get busqueda => _busqueda;

  /// Lista filtrada por nombre o email (case insensitive).
  List<UsuarioAdmin> get usuarios {
    if (_busqueda.isEmpty) return _usuarios;
    final q = _busqueda.toLowerCase();
    return _usuarios
        .where((u) =>
            u.nombre.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q))
        .toList();
  }

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _usuarios = await _repo.listarUsuarios();
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void filtrar(String texto) {
    _busqueda = texto;
    notifyListeners();
  }

  Future<bool> bloquear(int usuarioId, String motivo) async {
    try {
      await _repo.bloquearUsuario(usuarioId, motivo);
      await cargar();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> desbloquear(int usuarioId) async {
    try {
      await _repo.desbloquearUsuario(usuarioId);
      await cargar();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> crearAdmin({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      await _repo.crearAdmin(nombre: nombre, email: email, password: password);
      await cargar();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
