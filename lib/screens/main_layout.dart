import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_admin_provider.dart';
import 'admins/crear_admin_screen.dart';
import 'audit/audit_screen.dart';
import 'consejos/consejos_screen.dart';
import 'login_admin_screen.dart';
import 'metricas/metricas_screen.dart';
import 'usuarios/usuarios_screen.dart';

/// Layout principal del panel: NavigationRail extendido a la izquierda con
/// las 5 pestañas + botón logout, y a la derecha el contenido seleccionado.
///
/// Mantener el estado del índice aquí evita rebuild innecesario de las
/// pestañas al volver a abrirlas (las pestañas siguen vivas en sus providers).
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _indice = 0;

  static const _titulos = [
    'Usuarios',
    'Consejos',
    'Métricas',
    'Audit log',
    'Crear admin',
  ];

  static const List<Widget> _pantallas = [
    UsuariosScreen(),
    ConsejosScreen(),
    MetricasScreen(),
    AuditScreen(),
    CrearAdminScreen(),
  ];

  Future<void> _cerrarSesion() async {
    final auth = context.read<AuthAdminProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginAdminScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthAdminProvider>();
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            indiceSeleccionado: _indice,
            onSeleccionar: (i) => setState(() => _indice = i),
            emailAdmin: auth.emailActual ?? '',
            nombreAdmin: auth.nombreActual ?? 'Admin',
            onLogout: _cerrarSesion,
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _titulos[_indice],
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(child: _pantallas[_indice]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int indiceSeleccionado;
  final ValueChanged<int> onSeleccionar;
  final String nombreAdmin;
  final String emailAdmin;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.indiceSeleccionado,
    required this.onSeleccionar,
    required this.nombreAdmin,
    required this.emailAdmin,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('GrowTogether',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _entrada(context, 0, Icons.people_outline, 'Usuarios'),
                _entrada(context, 1, Icons.tips_and_updates_outlined, 'Consejos'),
                _entrada(context, 2, Icons.bar_chart_outlined, 'Métricas'),
                _entrada(context, 3, Icons.history, 'Audit log'),
                _entrada(context, 4, Icons.admin_panel_settings_outlined, 'Crear admin'),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        nombreAdmin.isNotEmpty ? nombreAdmin[0].toUpperCase() : 'A',
                        style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nombreAdmin, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(emailAdmin, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _entrada(BuildContext context, int indice, IconData icono, String etiqueta) {
    final colorScheme = Theme.of(context).colorScheme;
    final activo = indiceSeleccionado == indice;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: activo ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSeleccionar(indice),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icono, size: 20, color: activo ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Text(etiqueta,
                    style: TextStyle(
                      fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                      color: activo ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
