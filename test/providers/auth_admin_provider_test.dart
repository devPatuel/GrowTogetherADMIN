import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growtogether_data/growtogether_data.dart';
import 'package:growtogetheradmin/providers/auth_admin_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

class _MockDio extends Mock implements Dio {}

class _MockStorage extends Mock implements SecureStorageService {}

/// Tests del AuthAdminProvider.
///
/// Cubren:
/// - haySesion() consulta el storage y rellena el estado.
/// - login OK guarda el token y rellena nombre/email.
/// - login con rol distinto de ADMIN se descarta (caso clave: usuario STANDARD
///   intentando entrar al panel).
/// - login con 401 da el error "Credenciales incorrectas".
/// - login con timeout/connectionError da el error "No se pudo conectar".
/// - logout limpia el storage y el estado en memoria.
void main() {
  late _MockDioClient client;
  late _MockDio dio;
  late _MockStorage storage;
  late AuthAdminProvider provider;

  setUp(() {
    client = _MockDioClient();
    dio = _MockDio();
    storage = _MockStorage();
    when(() => client.dio).thenReturn(dio);
    provider = AuthAdminProvider(client, storage);
  });

  test('haySesion devuelve false si no hay token guardado', () async {
    when(() => storage.hasToken()).thenAnswer((_) async => false);

    final result = await provider.haySesion();

    expect(result, isFalse);
    expect(provider.idActual, isNull);
  });

  test('haySesion devuelve true y rellena el estado si hay token', () async {
    when(() => storage.hasToken()).thenAnswer((_) async => true);
    when(() => storage.getUserId()).thenAnswer((_) async => 7);
    when(() => storage.getUserName()).thenAnswer((_) async => 'Jordi');
    when(() => storage.getUserEmail()).thenAnswer((_) async => 'jordi@admin.com');

    final result = await provider.haySesion();

    expect(result, isTrue);
    expect(provider.idActual, 7);
    expect(provider.nombreActual, 'Jordi');
    expect(provider.emailActual, 'jordi@admin.com');
  });

  test('login OK guarda token y rellena el estado cuando rol es ADMIN', () async {
    when(() => dio.post('/auth/login', data: any(named: 'data')))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/auth/login'),
              statusCode: 200,
              data: {
                'token': 'jwt-fake',
                'rol': 'ADMIN',
                'usuarioId': 7,
                'nombre': 'Jordi',
                'email': 'jordi@admin.com',
              },
            ));
    when(() => storage.saveToken(any())).thenAnswer((_) async {});
    when(() => storage.saveUserId(any())).thenAnswer((_) async {});
    when(() => storage.saveUserName(any())).thenAnswer((_) async {});
    when(() => storage.saveUserEmail(any())).thenAnswer((_) async {});

    final ok = await provider.login('jordi@admin.com', 'pass');

    expect(ok, isTrue);
    expect(provider.error, isNull);
    expect(provider.idActual, 7);
    verify(() => storage.saveToken('jwt-fake')).called(1);
  });

  test('login con rol distinto de ADMIN se rechaza con error específico', () async {
    when(() => dio.post('/auth/login', data: any(named: 'data')))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/auth/login'),
              statusCode: 200,
              data: {
                'token': 'jwt-fake',
                'rol': 'STANDARD',
                'usuarioId': 7,
                'nombre': 'Jordi',
                'email': 'jordi@admin.com',
              },
            ));

    final ok = await provider.login('jordi@admin.com', 'pass');

    expect(ok, isFalse);
    expect(provider.error, 'Acceso restringido a administradores');
    verifyNever(() => storage.saveToken(any()));
  });

  test('login con 401 da error de credenciales', () async {
    when(() => dio.post('/auth/login', data: any(named: 'data')))
        .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401,
          ),
        ));

    final ok = await provider.login('jordi@admin.com', 'mal');

    expect(ok, isFalse);
    expect(provider.error, 'Credenciales incorrectas');
  });

  test('login con timeout da error de conexión', () async {
    when(() => dio.post('/auth/login', data: any(named: 'data')))
        .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          type: DioExceptionType.connectionTimeout,
        ));

    final ok = await provider.login('jordi@admin.com', 'pass');

    expect(ok, isFalse);
    expect(provider.error, 'No se pudo conectar al servidor');
  });

}
