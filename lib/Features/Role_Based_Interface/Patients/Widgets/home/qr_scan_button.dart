import 'package:flutter/material.dart';
import 'package:medicus/Utilities/colors.dart';

class QrScanButton extends StatelessWidget {
  const QrScanButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MColors.primaryColor.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.qr_code_2, color: MColors.primaryColor, size: 22),
        ),
      ),
    );
  }
}
