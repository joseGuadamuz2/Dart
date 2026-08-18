import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, filled }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final onTap = isLoading ? null : onPressed;
    final Widget child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  Flexible(child: Text(label)),
                ],
              )
            : Text(label);

    return SizedBox(
      width: double.infinity,
      child: switch (variant) {
        AppButtonVariant.primary =>
          ElevatedButton(onPressed: onTap, child: child),
        AppButtonVariant.secondary =>
          OutlinedButton(onPressed: onTap, child: child),
        AppButtonVariant.filled => FilledButton(onPressed: onTap, child: child),
      },
    );
  }
}