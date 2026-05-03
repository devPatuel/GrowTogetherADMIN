import 'package:flutter_test/flutter_test.dart';
import 'package:growtogether_data/growtogether_data.dart';
import 'package:growtogetheradmin/providers/metricas_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdminRepository extends Mock implements AdminRepository {}

/// Tests del MetricasProvider.
///
/// Es el provider más simple: una sola llamada que rellena el snapshot. Aún
/// así verificamos los 3 estados (inicial, OK, error) porque la pantalla
/// muestra spinner / contenido / mensaje en función de ellos.
void main() {
  late _MockAdminRepository repo;
  late MetricasProvider provider;

  setUp(() {
    repo = _MockAdminRepository();
    provider = MetricasProvider(repo);
  });

  test('estado inicial: sin métricas, sin error, no cargando', () {
    expect(provider.metricas, isNull);
    expect(provider.error, isNull);
    expect(provider.cargando, isFalse);
  });

  test('cargar OK rellena las métricas', () async {
    when(() => repo.obtenerMetricas()).thenAnswer((_) async => MetricasAdmin(
          totalUsuarios: 100,
          usuariosActivos: 80,
          totalHabitos: 250,
          habitosCompletadosHoy: 30,
          desafiosActivos: 5,
        ));

    await provider.cargar();

    expect(provider.metricas, isNotNull);
    expect(provider.metricas!.totalUsuarios, 100);
    expect(provider.error, isNull);
  });

  test('cargar con error guarda mensaje y deja métricas a null', () async {
    when(() => repo.obtenerMetricas()).thenThrow(Exception('timeout'));

    await provider.cargar();

    expect(provider.metricas, isNull);
    expect(provider.error, contains('timeout'));
  });
}
