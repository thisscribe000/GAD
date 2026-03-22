import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isFullWidth;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.isFullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final button = isOutlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
            label: Text(text),
          )
        : ElevatedButton.icon(
            onPressed: onPressed,
            icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
            label: Text(text),
          );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
