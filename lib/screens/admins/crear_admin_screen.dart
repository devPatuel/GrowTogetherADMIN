import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/snack_helper.dart';
import '../../providers/usuarios_admin_provider.dart';

/// Formulario para crear un nuevo administrador. Replica la política de
/// contraseña del backend (≥8 chars, mayús+minús+dígito) en cliente para
/// dar feedback inmediato.
class CrearAdminScreen extends StatefulWidget {
  const CrearAdminScreen({super.key});

  @override
  State<CrearAdminScreen> createState() => _CrearAdminScreenState();
}

class _CrearAdminScreenState extends State<CrearAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _passConfirm = TextEditingController();
  bool _ocultoPass = true;
  bool _enviando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _pass.dispose();
    _passConfirm.dispose();
    super.dispose();
  }

  String? _validarPass(String? v) {
    if (v == null || v.isEmpty) return 'La contraseña es obligatoria';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).+$');
    if (!regex.hasMatch(v)) {
      return 'Debe incluir mayúscula, minúscula, dígito y carácter especial';
    }
    return null;
  }

  String? _validarEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'El email es obligatorio';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(v.trim())) return 'Email no válido';
    return null;
  }

  Future<void> _crear() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _enviando = true);
    final estado = context.read<UsuariosAdminProvider>();
    final ok = await estado.crearAdmin(
      nombre: _nombre.text.trim(),
      email: _email.text.trim(),
      password: _pass.text,
    );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (ok) {
      _formKey.currentState?.reset();
      _nombre.clear();
      _email.clear();
      _pass.clear();
      _passConfirm.clear();
      context.showSnackSuccess('Admin creado correctamente');
    } else {
      context.showSnackError(estado.error ?? 'Error al crear el admin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Crear nuevo administrador',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'El nuevo usuario tendrá acceso completo al panel admin',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nombre,
                      decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.length < 2) return 'Mínimo 2 caracteres';
                        if (t.length > 100) return 'Máximo 100 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validarEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pass,
                      obscureText: _ocultoPass,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_ocultoPass ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _ocultoPass = !_ocultoPass),
                        ),
                        helperText: 'Mín 8 caracteres, una mayúscula, una minúscula, un dígito y un carácter especial',
                        helperMaxLines: 2,
                      ),
                      validator: _validarPass,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passConfirm,
                      obscureText: _ocultoPass,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) {
                        if (v != _pass.text) return 'Las contraseñas no coinciden';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _enviando ? null : _crear,
                      icon: _enviando
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add),
                      label: const Text('Crear admin'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
