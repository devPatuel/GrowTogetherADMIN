import 'package:flutter/material.dart';

/// Helpers de SnackBar reutilizables en todo el panel.
extension SnackHelper on BuildContext {
  void showSnack(String mensaje, {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(mensaje), duration: duration, behavior: SnackBarBehavior.floating),
    );
  }

  void showSnackError(String mensaje) {
    final color = Theme.of(this).colorScheme.error;
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showSnackSuccess(String mensaje) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
