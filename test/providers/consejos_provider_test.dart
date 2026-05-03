import 'package:flutter_test/flutter_test.dart';
import 'package:growtogether_data/growtogether_data.dart';
import 'package:growtogetheradmin/providers/consejos_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdminRepository extends Mock implements AdminRepository {}

Consejo _c(int id, String titulo, {DateTime? fecha, bool activo = true}) =>
    Consejo(id: id, titulo: titulo, descripcion: 'd', fechaPublicacion: fecha, activo: activo);

/// Tests del ConsejosProvider.
///
/// Cubren el CRUD completo y el helper "fechasOcupadas" usado por el date
/// picker de la pantalla para deshabilitar días con un consejo ya programado.
void main() {
  late _MockAdminRepository repo;
  late ConsejosProvider provider;

  setUp(() {
    repo = _MockAdminRepository();
    provider = ConsejosProvider(repo);
  });

  test('cargar OK rellena la lista de consejos', () async {
    when(() => repo.listarConsejos())
        .thenAnswer((_) async => [_c(1, 'Bebe agua'), _c(2, 'Duerme 8h')]);

    await provider.cargar();

    expect(provider.consejos.length, 2);
    expect(provider.error, isNull);
  });

  test('cargar con error guarda mensaje y deja lista vacía', () async {
    when(() => repo.listarConsejos()).thenThrow(Exception('500'));

    await provider.cargar();

    expect(provider.consejos, isEmpty);
    expect(provider.error, contains('500'));
  });

  test('crear OK invoca al repo y refresca', () async {
    when(() => repo.crearConsejo(
          titulo: any(named: 'titulo'),
          descripcion: any(named: 'descripcion'),
          fechaPublicacion: any(named: 'fechaPublicacion'),
          activo: any(named: 'activo'),
        )).thenAnswer((_) async => _c(1, 'Nuevo'));
    when(() => repo.listarConsejos()).thenAnswer((_) async => [_c(1, 'Nuevo')]);

    final ok = await provider.crear(titulo: 'Nuevo', descripcion: 'desc');

    expect(ok, isTrue);
    verify(() => repo.crearConsejo(
          titulo: 'Nuevo',
          descripcion: 'desc',
          fechaPublicacion: null,
          activo: true,
        )).called(1);
    expect(provider.consejos.length, 1);
  });

  test('crear con error devuelve false y guarda mensaje', () async {
    when(() => repo.crearConsejo(
          titulo: any(named: 'titulo'),
          descripcion: any(named: 'descripcion'),
          fechaPublicacion: any(named: 'fechaPublicacion'),
          activo: any(named: 'activo'),
        )).thenThrow(Exception('fecha duplicada'));

    final ok = await provider.crear(titulo: 'X', descripcion: 'Y');

    expect(ok, isFalse);
    expect(provider.error, contains('fecha duplicada'));
  });

  test('editar OK invoca al repo con el id', () async {
    when(() => repo.editarConsejo(
          any(),
          titulo: any(named: 'titulo'),
          descripcion: any(named: 'descripcion'),
          fechaPublicacion: any(named: 'fechaPublicacion'),
          activo: any(named: 'activo'),
        )).thenAnswer((_) async => _c(5, 'Editado'));
    when(() => repo.listarConsejos()).thenAnswer((_) async => [_c(5, 'Editado')]);

    final ok = await provider.editar(5,
        titulo: 'Editado', descripcion: 'd', activo: false);

    expect(ok, isTrue);
    verify(() => repo.editarConsejo(5,
        titulo: 'Editado',
        descripcion: 'd',
        fechaPublicacion: null,
        activo: false)).called(1);
  });

  test('eliminar OK invoca al repo con el id y refresca', () async {
    when(() => repo.eliminarConsejo(any())).thenAnswer((_) async {});
    when(() => repo.listarConsejos()).thenAnswer((_) async => []);

    final ok = await provider.eliminar(7);

    expect(ok, isTrue);
    verify(() => repo.eliminarConsejo(7)).called(1);
    expect(provider.consejos, isEmpty);
  });

  test('fechasOcupadas devuelve solo las fechas (sin hora) de consejos publicados', () async {
    when(() => repo.listarConsejos()).thenAnswer((_) async => [
          _c(1, 'a', fecha: DateTime(2026, 5, 10, 14, 30)),
          _c(2, 'b'), // sin fecha → no cuenta
          _c(3, 'c', fecha: DateTime(2026, 5, 11, 9, 0)),
        ]);
    await provider.cargar();

    final fechas = provider.fechasOcupadas;

    expect(fechas.length, 2);
    expect(fechas.contains(DateTime(2026, 5, 10)), isTrue);
    expect(fechas.contains(DateTime(2026, 5, 11)), isTrue);
  });

  test('eliminar con error devuelve false', () async {
    when(() => repo.eliminarConsejo(any())).thenThrow(Exception('en uso'));

    final ok = await provider.eliminar(7);

    expect(ok, isFalse);
    expect(provider.error, contains('en uso'));
  });
}
