import 'package:flutter/material.dart';

class AlertDialogCustom {
  /// Muestra un AlertDialog reutilizable
  void showAlertDialog(
      BuildContext context,
      String message,
      String heading,
      String buttonAcceptTitle, {
        VoidCallback? onOk,
      }) {
    showDialog(
      context: context,
      barrierDismissible: false, // 👈 evita cerrar tocando fuera del diálogo
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            heading,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                buttonAcceptTitle,
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // ✅ cierra correctamente
                if (onOk != null) {
                  onOk(); // Ejecuta acción extra si fue pasada
                }
              },
            ),
          ],
        );
      },
    );
  }
}
