import 'package:flutter_test/flutter_test.dart';
import 'package:growtogether_data/growtogether_data.dart';
import 'package:growtogetheradmin/providers/usuarios_admin_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdminRepository extends Mock implements AdminRepository {}

UsuarioAdmin _u(int id, String nombre, String email, {bool activo = true}) =>
    UsuarioAdmin(id: id, nombre: nombre, email: email, activo: activo);

/// Tests del UsuariosAdminProvider.
///
/// Cubren la lógica del CRUD de usuarios y el filtro de búsqueda en cliente.
/// Las acciones (bloquear, desbloquear, crearAdmin) refrescan la lista al
/// terminar, así que verificamos que el repo se llame y que el estado
/// se actualice correctamente.
void main() {
  late _MockAdminRepository repo;
  late UsuariosAdminProvider provider;

  setUp(() {
    repo = _MockAdminRepository();
    provider = UsuariosAdminProvider(repo);
  });

  test('cargar OK rellena la lista de usuarios', () async {
    when(() => repo.listarUsuarios())
        .thenAnswer((_) async => [_u(1, 'Ana', 'ana@x.com'), _u(2, 'Bob', 'bob@x.com')]);

    await provider.cargar();

    expect(provider.usuarios.length, 2);
    expect(provider.error, isNull);
  });

  test('cargar con error guarda el mensaje en error', () async {
    when(() => repo.listarUsuarios()).thenThrow(Exception('boom'));

    await provider.cargar();

    expect(provider.usuarios, isEmpty);
    expect(provider.error, contains('boom'));
  });

  test('busqueda vacía devuelve la lista completa', () async {
    when(() => repo.listarUsuarios())
        .thenAnswer((_) async => [_u(1, 'Ana', 'a@x.com'), _u(2, 'Bob', 'b@x.com')]);
    await provider.cargar();

    provider.filtrar('');

    expect(provider.usuarios.length, 2);
  });

  test('busqueda filtra por nombre case-insensitive', () async {
    when(() => repo.listarUsuarios())
        .thenAnswer((_) async => [_u(1, 'Ana', 'a@x.com'), _u(2, 'Bob', 'b@x.com')]);
    await provider.cargar();

    provider.filtrar('ANA');

    expect(provider.usuarios.length, 1);
    expect(provider.usuarios.first.nombre, 'Ana');
  });

  test('busqueda filtra por email', () async {
    when(() => repo.listarUsuarios())
        .thenAnswer((_) async => [_u(1, 'Ana', 'ana@x.com'), _u(2, 'Bob', 'bob@y.com')]);
    await provider.cargar();

    provider.filtrar('y.com');

    expect(provider.usuarios.length, 1);
    expect(provider.usuarios.first.email, 'bob@y.com');
  });

  test('bloquear OK invoca al repo y refresca la lista', () async {
    when(() => repo.bloquearUsuario(any(), any())).thenAnswer((_) async {});
    when(() => repo.listarUsuarios())
        .thenAnswer((_) async => [_u(1, 'Ana', 'a@x.com', activo: false)]);

    final ok = await provider.bloquear(1, 'spam');

    expect(ok, isTrue);
    verify(() => repo.bloquearUsuario(1, 'spam')).called(1);
    expect(provider.usuarios.first.activo, isFalse);
  });

  test('bloquear con error devuelve false y guarda mensaje', () async {
    when(() => repo.bloquearUsuario(any(), any())).thenThrow(Exception('403'));

    final ok = await provider.bloquear(1, 'spam');

    expect(ok, isFalse);
    expect(provider.error, contains('403'));
  });

  test('desbloquear OK invoca al repo', () async {
    when(() => repo.desbloquearUsuario(any())).thenAnswer((_) async {});
    when(() => repo.listarUsuarios())
        .thenAnswer((_) async => [_u(1, 'Ana', 'a@x.com')]);

    final ok = await provider.desbloquear(1);

    expect(ok, isTrue);
    verify(() => repo.desbloquearUsuario(1)).called(1);
  });

  test('crearAdmin OK invoca al repo con los datos del formulario', () async {
    when(() => repo.crearAdmin(
          nombre: any(named: 'nombre'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => _u(99, 'Nuevo', 'nuevo@x.com'));
    when(() => repo.listarUsuarios()).thenAnswer((_) async => []);

    final ok = await provider.crearAdmin(
      nombre: 'Nuevo',
      email: 'nuevo@x.com',
      password: 'Pass1234',
    );

    expect(ok, isTrue);
    verify(() => repo.crearAdmin(
          nombre: 'Nuevo',
          email: 'nuevo@x.com',
          password: 'Pass1234',
        )).called(1);
  });
}
