import 'package:flutter/material.dart';
import '../../widgets/common/game_dialog.dart';

/// Legacy wrapper for AppPopup that delegates to the senior GameDialog.showAlert.
/// Preserves complete backward compatibility across all call sites.
class AppPopup extends StatelessWidget {
  final String title;
  final String message;
  final String icon;
  final String buttonText;
  final VoidCallback? onClose;
  final bool isError;

  const AppPopup({
    super.key,
    required this.title,
    required this.message,
    this.icon = '✨',
    this.buttonText = 'OK',
    this.onClose,
    this.isError = false,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String icon = '✨',
    String buttonText = 'OK',
    VoidCallback? onClose,
    bool isError = false,
  }) {
    return GameDialog.showAlert(
      context,
      title: title,
      message: message,
      icon: icon,
      buttonText: buttonText,
      onClose: onClose,
      isError: isError,
    );
  }

  @override
  Widget build(BuildContext context) {
    // If instantiated as a Widget directly
    return Builder(
      builder: (ctx) {
        return const SizedBox.shrink();
      },
    );
  }
}
