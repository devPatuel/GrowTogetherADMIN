import 'package:flutter_test/flutter_test.dart';
import 'package:growtogether_data/growtogether_data.dart';
import 'package:growtogetheradmin/providers/audit_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdminRepository extends Mock implements AdminRepository {}

AuditLog _log(int id, {
  String accion = 'CREATE',
  String entidad = 'USUARIO',
  String? email,
  DateTime? fecha,
}) =>
    AuditLog(
      id: id,
      accion: accion,
      entidad: entidad,
      usuarioId: 1,
      usuarioEmail: email,
      fecha: fecha ?? DateTime(2026, 5, 1),
    );

/// Tests del AuditProvider.
///
/// El provider mantiene la lista descargada y aplica los filtros en cliente
/// (admin/entidad/acción/rango fechas). Cubrimos cada filtro por separado y
/// el helper "limpiarFiltros".
void main() {
  late _MockAdminRepository repo;
  late AuditProvider provider;

  setUp(() {
    repo = _MockAdminRepository();
    provider = AuditProvider(repo);
  });

  test('cargar OK rellena la lista', () async {
    when(() => repo.listarAuditLog())
        .thenAnswer((_) async => [_log(1), _log(2)]);

    await provider.cargar();

    expect(provider.logs.length, 2);
    expect(provider.error, isNull);
  });

  test('cargar con error guarda mensaje', () async {
    when(() => repo.listarAuditLog()).thenThrow(Exception('500'));

    await provider.cargar();

    expect(provider.logs, isEmpty);
    expect(provider.error, contains('500'));
  });

  test('filtroAdmin filtra por email del admin que ejecutó la acción', () async {
    when(() => repo.listarAuditLog()).thenAnswer((_) async => [
          _log(1, email: 'jordi@admin.com'),
          _log(2, email: 'otro@admin.com'),
        ]);
    await provider.cargar();

    provider.setFiltroAdmin('jordi');

    expect(provider.logs.length, 1);
    expect(provider.logs.first.usuarioEmail, 'jordi@admin.com');
  });

  test('filtroEntidad filtra por entidad afectada', () async {
    when(() => repo.listarAuditLog()).thenAnswer((_) async => [
          _log(1, entidad: 'USUARIO'),
          _log(2, entidad: 'CONSEJO'),
        ]);
    await provider.cargar();

    provider.setFiltroEntidad('CONSEJO');

    expect(provider.logs.length, 1);
    expect(provider.logs.first.entidad, 'CONSEJO');
  });

  test('filtroAccion filtra por acción ejecutada', () async {
    when(() => repo.listarAuditLog()).thenAnswer((_) async => [
          _log(1, accion: 'CREATE'),
          _log(2, accion: 'DELETE'),
        ]);
    await provider.cargar();

    provider.setFiltroAccion('DELETE');

    expect(provider.logs.length, 1);
    expect(provider.logs.first.accion, 'DELETE');
  });

  test('rango fechas excluye logs fuera del intervalo', () async {
    when(() => repo.listarAuditLog()).thenAnswer((_) async => [
          _log(1, fecha: DateTime(2026, 4, 15)),
          _log(2, fecha: DateTime(2026, 5, 1)),
          _log(3, fecha: DateTime(2026, 6, 10)),
        ]);
    await provider.cargar();

    provider.setRango(DateTime(2026, 5, 1), DateTime(2026, 5, 31));

    expect(provider.logs.length, 1);
    expect(provider.logs.first.id, 2);
  });

  test('limpiarFiltros restaura la lista completa', () async {
    when(() => repo.listarAuditLog()).thenAnswer((_) async => [
          _log(1, email: 'a@x.com'),
          _log(2, email: 'b@x.com'),
        ]);
    await provider.cargar();
    provider.setFiltroAdmin('a@x');
    expect(provider.logs.length, 1);

    provider.limpiarFiltros();

    expect(provider.logs.length, 2);
    expect(provider.filtroAdmin, isEmpty);
  });

  test('adminsDisponibles devuelve emails únicos y ordenados', () async {
    when(() => repo.listarAuditLog()).thenAnswer((_) async => [
          _log(1, email: 'b@x.com'),
          _log(2, email: 'a@x.com'),
          _log(3, email: 'a@x.com'),
        ]);
    await provider.cargar();

    expect(provider.adminsDisponibles, ['a@x.com', 'b@x.com']);
  });

  test('entidadesDisponibles devuelve entidades únicas y ordenadas', () async {
    when(() => repo.listarAuditLog()).thenAnswer((_) async => [
          _log(1, entidad: 'USUARIO'),
          _log(2, entidad: 'CONSEJO'),
          _log(3, entidad: 'USUARIO'),
        ]);
    await provider.cargar();

    expect(provider.entidadesDisponibles, ['CONSEJO', 'USUARIO']);
  });

}
