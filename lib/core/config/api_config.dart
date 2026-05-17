import 'package:growtogether_data/growtogether_data.dart';

/// Configuración de acceso a la API REST para el panel admin.
///
/// La URL se inyecta vía `--dart-define=API_URL=http://...` al ejecutar
/// `flutter run -d chrome`. Si no se especifica, se usa el fallback local
/// hacia el backend Spring Boot en localhost:8081.
ApiConfig buildAdminApiConfig() {
  return ApiConfig.fromEnv(fallback: 'http://localhost:8081/api/v1');
}
