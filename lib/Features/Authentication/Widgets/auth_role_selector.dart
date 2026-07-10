import 'package:flutter/material.dart';

import '../Models/auth_role.dart';
import 'package:medicus/Utilities/colors.dart';

class AuthRoleSelector extends StatelessWidget {
  const AuthRoleSelector({
    super.key,
    required this.selectedRole,
    required this.dark,
    required this.onChanged,
  });

  final AuthRole? selectedRole;
  final bool dark;
  final ValueChanged<AuthRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 360;
        final double iconSize = compact ? 24 : 30;
        final double labelSize = compact ? 11 : 12;

        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: compact ? 1.0 : 1.18,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: AuthRole.values
              .map(
                (AuthRole role) => OutlinedButton(
                  onPressed: () => onChanged(role),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selectedRole == role ? MColors.primaryColor.withValues(alpha: 0.08) : null,
                    side: BorderSide(color: dark ? Colors.white : MColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(role.icon, color: dark ? Colors.white : MColors.primaryColor, size: iconSize),
                      const SizedBox(height: 6),
                      Text(
                        _buttonLabel(role),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: dark ? Colors.white : MColors.primaryColor,
                          fontSize: labelSize,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  String _buttonLabel(AuthRole role) {
    switch (role) {
      case AuthRole.pharmacist:
        return 'Pharmacy';
      case AuthRole.labSpecialist:
        return 'Lab Specialist';
      default:
        return role.label;
    }
  }
}
