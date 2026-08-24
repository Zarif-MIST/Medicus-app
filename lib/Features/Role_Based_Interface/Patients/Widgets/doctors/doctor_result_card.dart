import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class DoctorSummary {
  const DoctorSummary({
    required this.doctorId,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.rating,
    required this.experienceYears,
    required this.fee,
    required this.nextAvailable,
  });

  /// Empty for the (soon to be retired) hand-authored demo doctors; a real
  /// registered doctor's `AuthAccount.userId` otherwise — required for a
  /// booking to reach that doctor's real appointment list.
  final String doctorId;
  final String name;
  final String specialty;
  final String hospital;
  final double rating;
  final int experienceYears;
  final int fee;
  final String nextAvailable;

  /// Registration only collects a doctor's name and specialty today — the
  /// hospital/fee/experience/rating/availability fields below don't exist
  /// in the schema yet, so real doctors show honest placeholders for them
  /// instead of fabricated numbers.
  factory DoctorSummary.fromAuthAccount(AuthAccount account) {
    final String rawName = account.fullName.trim();
    final String displayName = rawName.isEmpty
        ? 'Dr. Unnamed'
        : (rawName.toLowerCase().startsWith('dr') ? rawName : 'Dr. $rawName');

    return DoctorSummary(
      doctorId: account.userId,
      name: displayName,
      specialty: (account.specialty ?? '').trim().isEmpty ? 'General' : account.specialty!.trim(),
      hospital: '',
      rating: 0,
      experienceYears: 0,
      fee: 0,
      nextAvailable: 'Book to request a time',
    );
  }
}

class DoctorResultCard extends StatelessWidget {
  const DoctorResultCard({
    super.key,
    required this.doctor,
    required this.onTap,
  });

  final DoctorSummary doctor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return LiquidGlassLayer(
      settings: LiquidGlassSettings(
        thickness: 16,
        blur: 10,
        glassColor: isDark ? const Color(0x22FFFFFF) : const Color(0x92FFFFFF),
        lightIntensity: 1.05,
        saturation: 1.12,
        refractiveIndex: 1.25,
      ),
      fake: true,
      child: LiquidGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: 16),
        child: Material(
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: MColors.primaryColor.withValues(
                      alpha: 0.12,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: MColors.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctor.name, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          doctor.experienceYears > 0
                              ? '${doctor.specialty} • ${doctor.experienceYears} yrs exp'
                              : doctor.specialty,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        if (doctor.hospital.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            doctor.hospital,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (doctor.rating > 0) ...[
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                doctor.rating.toStringAsFixed(1),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Flexible(
                              child: Text(
                                doctor.fee > 0 ? '৳${doctor.fee}' : 'Fee on request',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: MColors.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          doctor.nextAvailable,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
