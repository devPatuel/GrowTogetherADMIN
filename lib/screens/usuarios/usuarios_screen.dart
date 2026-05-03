import 'dart:convert';
import 'dart:typed_data';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:growtogether_data/growtogether_data.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/snack_helper.dart';
import '../../providers/auth_admin_provider.dart';
import '../../providers/usuarios_admin_provider.dart';
import 'widgets/bloquear_dialog.dart';

/// Pestaña de gestión de usuarios. Tabla con búsqueda + acciones de
/// bloquear (con motivo) y desbloquear.
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  bool _yaCargado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_yaCargado) {
      _yaCargado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<UsuariosAdminProvider>().cargar();
      });
    }
  }

  Future<void> _bloquear(UsuarioAdmin u) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => BloquearDialog(nombreUsuario: u.nombre),
    );
    if (motivo == null || !mounted) return;
    final ok = await context.read<UsuariosAdminProvider>().bloquear(u.id, motivo);
    if (!mounted) return;
    if (ok) {
      context.showSnackSuccess('Usuario bloqueado');
    } else {
      context.showSnackError(context.read<UsuariosAdminProvider>().error ?? 'Error');
    }
  }

  Future<void> _desbloquear(UsuarioAdmin u) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desbloquear usuario'),
        content: Text('¿Restablecer el acceso de ${u.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Desbloquear')),
        ],
      ),
    );
    if (confirma != true || !mounted) return;
    final ok = await context.read<UsuariosAdminProvider>().desbloquear(u.id);
    if (!mounted) return;
    if (ok) {
      context.showSnackSuccess('Usuario desbloqueado');
    } else {
      context.showSnackError(context.read<UsuariosAdminProvider>().error ?? 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<UsuariosAdminProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o email',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: estado.filtrar,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: estado.cargando ? null : () => estado.cargar(),
                icon: const Icon(Icons.refresh),
                label: const Text('Refrescar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: estado.cargando && estado.usuarios.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : (estado.error != null && estado.usuarios.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, color: colorScheme.error, size: 32),
                              const SizedBox(height: 8),
                              Text(estado.error!),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: () => estado.cargar(),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : DataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 16,
                          minWidth: 900,
                          headingRowColor: WidgetStateProperty.all(colorScheme.surfaceContainerLow),
                          columns: const [
                            DataColumn2(label: Text(''), fixedWidth: 56),
                            DataColumn2(label: Text('Nombre'), size: ColumnSize.L),
                            DataColumn2(label: Text('Email'), size: ColumnSize.L),
                            DataColumn2(label: Text('Rol'), fixedWidth: 90),
                            DataColumn2(label: Text('Registro'), fixedWidth: 110),
                            DataColumn2(label: Text('Estado'), fixedWidth: 130),
                            DataColumn2(label: Text('Acciones'), fixedWidth: 200),
                          ],
                          rows: estado.usuarios.map(_filaUsuario).toList(),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _filaUsuario(UsuarioAdmin u) {
    return DataRow(
      cells: [
        DataCell(_avatar(u)),
        DataCell(Text(u.nombre, maxLines: 1, overflow: TextOverflow.ellipsis)),
        DataCell(Text(u.email, maxLines: 1, overflow: TextOverflow.ellipsis)),
        DataCell(Text(u.rol ?? '—')),
        DataCell(Text(Formatters.fecha(u.fechaRegistro))),
        DataCell(_chipEstado(u)),
        DataCell(_acciones(u)),
      ],
    );
  }

  Widget _avatar(UsuarioAdmin u) {
    if (u.foto != null && u.foto!.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(u.foto!);
        return CircleAvatar(backgroundImage: MemoryImage(bytes), radius: 18);
      } catch (_) {
        // foto inválida, cae al placeholder
      }
    }
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 18,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        u.nombre.isNotEmpty ? u.nombre[0].toUpperCase() : '?',
        style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _chipEstado(UsuarioAdmin u) {
    final colorScheme = Theme.of(context).colorScheme;
    if (u.activo) {
      return Chip(
        label: const Text('Activo'),
        backgroundColor: Colors.green.shade100,
        labelStyle: TextStyle(color: Colors.green.shade900),
        side: BorderSide.none,
      );
    }
    return Tooltip(
      message: u.motivoBloqueo == null
          ? 'Bloqueado'
          : 'Bloqueado el ${Formatters.fecha(u.fechaBloqueo)}\nMotivo: ${u.motivoBloqueo}',
      child: Chip(
        label: const Text('Bloqueado'),
        backgroundColor: colorScheme.errorContainer,
        labelStyle: TextStyle(color: colorScheme.onErrorContainer),
        side: BorderSide.none,
      ),
    );
  }

  Widget _acciones(UsuarioAdmin u) {
    final idActual = context.read<AuthAdminProvider>().idActual;
    final esYoMismo = idActual != null && idActual == u.id;
    if (u.activo) {
      if (esYoMismo) {
        return Tooltip(
          message: 'No puedes bloquearte a ti mismo',
          child: TextButton.icon(
            onPressed: null,
            icon: const Icon(Icons.block, size: 18),
            label: const Text('Bloquear'),
          ),
        );
      }
      return TextButton.icon(
        onPressed: () => _bloquear(u),
        icon: const Icon(Icons.block, size: 18),
        label: const Text('Bloquear'),
        style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
      );
    }
    return TextButton.icon(
      onPressed: () => _desbloquear(u),
      icon: const Icon(Icons.lock_open, size: 18),
      label: const Text('Desbloquear'),
    );
  }
}
