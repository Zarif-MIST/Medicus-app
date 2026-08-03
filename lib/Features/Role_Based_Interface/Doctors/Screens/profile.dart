import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Authentication/Screens/login/login.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.account});

  final AuthAccount account;

  List<_ProfileField> get _profileFields {
    if (account.licenseNumber != null || account.specialty != null) {
      return <_ProfileField>[
        _ProfileField(label: 'Full name', value: account.fullName),
        _ProfileField(label: 'Email', value: account.email),
        _ProfileField(label: 'Phone', value: account.phoneNumber),
        _ProfileField(
          label: 'Specialty',
          value: account.specialty ?? 'General Physician',
        ),
        _ProfileField(
          label: 'BMDC license',
          value: account.licenseNumber ?? 'Not provided',
        ),
        _ProfileField(label: 'Gender', value: account.gender ?? 'Not provided'),
      ];
    }

    if (account.pharmacyName != null || account.tradeLicense != null) {
      return <_ProfileField>[
        _ProfileField(label: 'Full name', value: account.fullName),
        _ProfileField(label: 'Email', value: account.email),
        _ProfileField(label: 'Phone', value: account.phoneNumber),
        _ProfileField(
          label: 'Pharmacy name',
          value: account.pharmacyName ?? 'Not provided',
        ),
        _ProfileField(
          label: 'Trade license',
          value: account.tradeLicense ?? 'Not provided',
        ),
        _ProfileField(
          label: 'Pharmacy location',
          value: account.pharmacyLocation ?? 'Not provided',
        ),
        _ProfileField(
          label: 'NID number',
          value: account.nidNumber ?? 'Not provided',
        ),
      ];
    }

    return <_ProfileField>[
      _ProfileField(label: 'Full name', value: account.fullName),
      _ProfileField(label: 'Email', value: account.email),
      _ProfileField(label: 'Phone', value: account.phoneNumber),
      _ProfileField(label: 'Staff ID', value: account.userId),
      _ProfileField(
        label: 'Department',
        value: account.specialty ?? 'Lab Specialist',
      ),
      _ProfileField(
        label: 'Location',
        value: account.pharmacyLocation ?? 'Hospital lab unit',
      ),
    ];
  }

  Future<void> _editProfile(BuildContext context) async {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final fields = _profileFields;
    final controllers = [
      for (final field in fields) TextEditingController(text: field.value),
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Profile',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                for (int i = 0; i < fields.length; i++) ...[
                  TextField(
                    controller: controllers[i],
                    decoration: InputDecoration(
                      labelText: fields[i].label,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double pad = Sizes.responsivePadding(context);
    final fields = _profileFields;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF181818)
          : const Color(0xFFF7F5F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(pad, 8, pad, 120),
        children: [
          LiquidGlassLayer(
            settings: LiquidGlassSettings(
              thickness: 18,
              blur: 10,
              glassColor: isDark
                  ? const Color(0x22FFFFFF)
                  : const Color(0x92FFFFFF),
              lightIntensity: 1.05,
              saturation: 1.12,
              refractiveIndex: 1.25,
            ),
            child: LiquidGlass(
              shape: LiquidRoundedSuperellipse(borderRadius: 24),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: MColors.primaryColor.withValues(
                            alpha: 0.14,
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
                              Text(
                                account.fullName,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                account.email,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _editProfile(context),
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: MColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final field in fields) ...[
                      _DoctorProfileRow(label: field.label, value: field.value),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Get.offAll(
              () => const LoginScreen(),
              transition: Transition.fadeIn,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: MColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _ProfileField {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;
}

class _DoctorProfileRow extends StatelessWidget {
  const _DoctorProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
