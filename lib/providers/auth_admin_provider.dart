import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:growtogether_data/growtogether_data.dart';

/// Provider de autenticación del panel admin.
///
/// Reusa el endpoint POST /auth/login. Tras un login correcto verifica que el
/// rol del usuario sea ADMIN: si no, descarta el token y propaga un error
/// específico para que la pantalla de login lo muestre.
class AuthAdminProvider extends ChangeNotifier {
  final DioClient _client;
  final SecureStorageService _storage;

  AuthAdminProvider(this._client, this._storage);

  bool _cargando = false;
  String? _error;
  String? _emailActual;
  int? _idActual;
  String? _nombreActual;

  bool get cargando => _cargando;
  String? get error => _error;
  String? get emailActual => _emailActual;
  int? get idActual => _idActual;
  String? get nombreActual => _nombreActual;

  /// Comprueba al arrancar la app si hay sesión guardada.
  Future<bool> haySesion() async {
    if (await _storage.hasToken()) {
      _idActual = await _storage.getUserId();
      _nombreActual = await _storage.getUserName();
      _emailActual = await _storage.getUserEmail();
      return true;
    }
    return false;
  }

  /// Inicia sesión y verifica rol ADMIN. Devuelve true si todo OK.
  Future<bool> login(String email, String password) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _client.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      final rol = data['rol'] as String?;
      if (token == null) {
        _error = 'Respuesta inválida del servidor';
        return false;
      }
      if (rol != 'ADMIN') {
        _error = 'Acceso restringido a administradores';
        return false;
      }
      await _storage.saveToken(token);
      _idActual = (data['usuarioId'] as num?)?.toInt();
      _nombreActual = data['nombre'] as String?;
      _emailActual = data['email'] as String? ?? email;
      if (_idActual != null) await _storage.saveUserId(_idActual!);
      if (_nombreActual != null) await _storage.saveUserName(_nombreActual!);
      await _storage.saveUserEmail(_emailActual!);
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _error = 'Credenciales incorrectas';
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        _error = 'No se pudo conectar al servidor';
      } else {
        _error = 'Error al iniciar sesión';
      }
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _idActual = null;
    _nombreActual = null;
    _emailActual = null;
    notifyListeners();
  }
}
