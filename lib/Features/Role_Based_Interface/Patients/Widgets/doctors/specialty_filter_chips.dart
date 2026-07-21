import 'package:flutter/material.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class Specialty {
  const Specialty({required this.name, required this.icon});

  final String name;
  final IconData icon;
}

const List<Specialty> kSpecialties = [
  Specialty(name: 'General', icon: Icons.medical_information_outlined),
  Specialty(name: 'Cardiologist', icon: Icons.favorite_border),
  Specialty(name: 'Dermatologist', icon: Icons.face_outlined),
  Specialty(name: 'Pediatrician', icon: Icons.child_care_outlined),
  Specialty(name: 'Orthopedic', icon: Icons.accessibility_new_outlined),
  Specialty(name: 'Dentist', icon: Icons.sentiment_satisfied_outlined),
  Specialty(name: 'Gynecologist', icon: Icons.pregnant_woman_outlined),
  Specialty(name: 'ENT', icon: Icons.hearing_outlined),
  Specialty(name: 'Psychiatrist', icon: Icons.psychology_outlined),
  Specialty(name: 'Neurologist', icon: Icons.bolt_outlined),
];

/// Horizontal, single-line pill chips — tapping toggles selection
/// (tapping the active one again clears the filter).
class SpecialtyFilterChips extends StatelessWidget {
  const SpecialtyFilterChips({
    super.key,
    required this.specialties,
    required this.selected,
    required this.onSelected,
  });

  final List<Specialty> specialties;
  final Specialty? selected;
  final ValueChanged<Specialty> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: specialties.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final Specialty specialty = specialties[index];
          final bool isSelected = specialty.name == selected?.name;
          return _SpecialtyChip(
            specialty: specialty,
            selected: isSelected,
            onTap: () => onSelected(specialty),
          );
        },
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip({required this.specialty, required this.selected, required this.onTap});

  final Specialty specialty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Material(
      color: selected ? MColors.primaryColor : (isDark ? const Color(0xFF1F1F1F) : Colors.grey.shade100),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(specialty.icon, size: 16, color: selected ? Colors.white : MColors.primaryColor),
              const SizedBox(width: 6),
              Text(
                specialty.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
