import 'package:flutter/material.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class DoctorSearchBar extends StatelessWidget {
  const DoctorSearchBar({super.key, this.onSubmitted});

  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: 'Search specialist or doctor name',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
