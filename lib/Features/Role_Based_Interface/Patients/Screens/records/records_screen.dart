import 'package:flutter/material.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MHelperFunctions.isDarkMode(context) ? const Color(0xFF181818) : Colors.white,
      alignment: Alignment.center,
      child: const Text(
        'Records',
        style: TextStyle(color: MColors.primaryColor, fontSize: 32, fontWeight: FontWeight.bold),
      ),
    );
  }
}
