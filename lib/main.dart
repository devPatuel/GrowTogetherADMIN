import 'package:flutter/material.dart';
import 'package:growtogether_data/growtogether_data.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/config/api_config.dart';
import 'core/theme/app_theme.dart';
import 'providers/audit_provider.dart';
import 'providers/auth_admin_provider.dart';
import 'providers/consejos_provider.dart';
import 'providers/metricas_provider.dart';
import 'providers/usuarios_admin_provider.dart';
import 'screens/login_admin_screen.dart';
import 'screens/main_layout.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');

  final apiConfig = buildAdminApiConfig();
  final storage = SecureStorageService();
  final dio = DioClient(apiConfig, storage);
  final adminRepo = AdminRepository(dio);

  runApp(GrowTogetherAdminApp(
    storage: storage,
    dio: dio,
    adminRepo: adminRepo,
  ));
}

class GrowTogetherAdminApp extends StatelessWidget {
  final SecureStorageService storage;
  final DioClient dio;
  final AdminRepository adminRepo;

  const GrowTogetherAdminApp({
    super.key,
    required this.storage,
    required this.dio,
    required this.adminRepo,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SecureStorageService>.value(value: storage),
        Provider<DioClient>.value(value: dio),
        Provider<AdminRepository>.value(value: adminRepo),
        ChangeNotifierProvider(create: (_) => AuthAdminProvider(dio, storage)),
        ChangeNotifierProvider(create: (_) => UsuariosAdminProvider(adminRepo)),
        ChangeNotifierProvider(create: (_) => ConsejosProvider(adminRepo)),
        ChangeNotifierProvider(create: (_) => MetricasProvider(adminRepo)),
        ChangeNotifierProvider(create: (_) => AuditProvider(adminRepo)),
      ],
      child: MaterialApp(
        title: 'GrowTogether Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _Bootstrap(),
      ),
    );
  }
}

/// Decide la pantalla inicial: si hay token guardado, entra al panel,
/// si no, muestra el login.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  bool _comprobando = true;
  bool _logueado = false;

  @override
  void initState() {
    super.initState();
    _comprobarSesion();
  }

  Future<void> _comprobarSesion() async {
    final auth = context.read<AuthAdminProvider>();
    final ok = await auth.haySesion();
    if (!mounted) return;
    setState(() {
      _logueado = ok;
      _comprobando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_comprobando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _logueado ? const MainLayout() : const LoginAdminScreen();
  }
}
