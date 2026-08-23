import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Authentication/Models/auth_role.dart';
import 'package:medicus/Features/Authentication/Screens/login/login.dart';
import 'package:medicus/Features/Authentication/Services/auth_registry.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';

enum _StakeholderRole { doctor, pharmacist, labSpecialist }

enum _ProfileTab { personal, secondary }

BoxDecoration _cardDecoration(bool isDark) {
  return BoxDecoration(
    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.account});

  final AuthAccount account;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final _StakeholderRole _role;

  late String _firstName;
  late String _lastName;
  late String _phone;
  late String _email;
  String _gender = 'Not provided';

  String _specialty = 'General Physician';
  String _licenseNumber = 'Not provided';

  String _pharmacyName = 'Not provided';
  String _tradeLicense = 'Not provided';
  String _pharmacyLocation = 'Not provided';
  String _nidNumber = 'Not provided';
  String _pharmacistRegistrationNumber = 'Not provided';

  late String _staffId;
  String _department = 'Lab Specialist';
  String _labLocation = 'Hospital lab unit';

  _ProfileTab _activeTab = _ProfileTab.personal;

  @override
  void initState() {
    super.initState();
    final AuthAccount account = widget.account;
    _firstName = account.firstName;
    _lastName = account.lastName;
    _phone = account.phoneNumber;
    _email = account.email;
    _staffId = account.userId;

    if (account.role == AuthRole.doctor) {
      _role = _StakeholderRole.doctor;
      _specialty = account.specialty ?? _specialty;
      _licenseNumber = account.licenseNumber ?? _licenseNumber;
      _gender = account.gender ?? _gender;
    } else if (account.role == AuthRole.pharmacist) {
      _role = _StakeholderRole.pharmacist;
      _pharmacyName = account.pharmacyName ?? _pharmacyName;
      _tradeLicense = account.tradeLicense ?? _tradeLicense;
      _pharmacyLocation = account.pharmacyLocation ?? _pharmacyLocation;
      _nidNumber = account.nidNumber ?? _nidNumber;
      _pharmacistRegistrationNumber =
          account.pharmacistRegistrationNumber ?? _pharmacistRegistrationNumber;
    } else {
      _role = _StakeholderRole.labSpecialist;
      _department = account.specialty ?? _department;
      _labLocation = account.pharmacyLocation ?? _labLocation;
    }
  }

  String get _fullName => '$_firstName $_lastName'.trim();

  String get _secondaryTabLabel {
    switch (_role) {
      case _StakeholderRole.doctor:
        return 'Professional';
      case _StakeholderRole.pharmacist:
        return 'Business';
      case _StakeholderRole.labSpecialist:
        return 'Work';
    }
  }

  String get _idPillLabel {
    switch (_role) {
      case _StakeholderRole.doctor:
        return 'BMDC License · $_licenseNumber';
      case _StakeholderRole.pharmacist:
        return 'PCB Reg · $_pharmacistRegistrationNumber';
      case _StakeholderRole.labSpecialist:
        return 'Staff ID · $_staffId';
    }
  }

  Future<void> _persistToFirestore(Map<String, dynamic> fields) async {
    final String? uid = widget.account.firebaseUid;
    if (uid == null || uid.isEmpty || fields.isEmpty) {
      return;
    }

    try {
      await AuthRegistry.instance.updateProfileFields(uid, fields);
    } catch (_) {
      if (!mounted) {
        return;
      }
      Get.snackbar(
        'Update failed',
        'Could not save your changes. Check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _editSection({
    required String title,
    required List<String> labels,
    required List<String> values,
    required List<String?> firestoreKeys,
    required void Function(List<String> newValues) onSave,
  }) async {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final controllers = [
      for (final v in values) TextEditingController(text: v),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit $title',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < labels.length; i++) ...[
                TextField(
                  controller: controllers[i],
                  decoration: InputDecoration(
                    labelText: labels[i],
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
                  onPressed: () {
                    final List<String> newValues = [
                      for (final c in controllers) c.text.trim(),
                    ];
                    onSave(newValues);
                    Navigator.of(sheetContext).pop();

                    final Map<String, dynamic> fields = <String, dynamic>{
                      for (int i = 0; i < firestoreKeys.length; i++)
                        if (firestoreKeys[i] != null)
                          firestoreKeys[i]!: newValues[i],
                    };
                    _persistToFirestore(fields);
                  },
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
        );
      },
    );
  }

  void _editPersonalInfo() {
    switch (_role) {
      case _StakeholderRole.doctor:
        _editSection(
          title: 'Personal Info',
          labels: const ['First Name', 'Last Name', 'Phone', 'Email', 'Gender'],
          values: [_firstName, _lastName, _phone, _email, _gender],
          firestoreKeys: const [
            'firstName',
            'lastName',
            'phoneNumber',
            'email',
            'gender',
          ],
          onSave: (v) => setState(() {
            _firstName = v[0];
            _lastName = v[1];
            _phone = v[2];
            _email = v[3];
            _gender = v[4];
          }),
        );
        break;
      case _StakeholderRole.pharmacist:
        _editSection(
          title: 'Personal Info',
          labels: const [
            'First Name',
            'Last Name',
            'Phone',
            'Email',
            'NID Number',
          ],
          values: [_firstName, _lastName, _phone, _email, _nidNumber],
          firestoreKeys: const [
            'firstName',
            'lastName',
            'phoneNumber',
            'email',
            'nidNumber',
          ],
          onSave: (v) => setState(() {
            _firstName = v[0];
            _lastName = v[1];
            _phone = v[2];
            _email = v[3];
            _nidNumber = v[4];
          }),
        );
        break;
      case _StakeholderRole.labSpecialist:
        _editSection(
          title: 'Personal Info',
          labels: const ['First Name', 'Last Name', 'Phone', 'Email'],
          values: [_firstName, _lastName, _phone, _email],
          firestoreKeys: const [
            'firstName',
            'lastName',
            'phoneNumber',
            'email',
          ],
          onSave: (v) => setState(() {
            _firstName = v[0];
            _lastName = v[1];
            _phone = v[2];
            _email = v[3];
          }),
        );
        break;
    }
  }

  void _editSecondaryInfo() {
    switch (_role) {
      case _StakeholderRole.doctor:
        _editSection(
          title: 'Professional Info',
          labels: const ['Specialty', 'BMDC License Number'],
          values: [_specialty, _licenseNumber],
          firestoreKeys: const ['specialty', 'licenseNumber'],
          onSave: (v) => setState(() {
            _specialty = v[0];
            _licenseNumber = v[1];
          }),
        );
        break;
      case _StakeholderRole.pharmacist:
        _editSection(
          title: 'Business Info',
          labels: const [
            'Pharmacy Council Registration Number',
            'Pharmacy Name',
            'Trade License',
            'Pharmacy Location',
          ],
          values: [
            _pharmacistRegistrationNumber,
            _pharmacyName,
            _tradeLicense,
            _pharmacyLocation,
          ],
          firestoreKeys: const [
            'pharmacistRegistrationNumber',
            'pharmacyName',
            'tradeLicense',
            'pharmacyLocation',
          ],
          onSave: (v) => setState(() {
            _pharmacistRegistrationNumber = v[0];
            _pharmacyName = v[1];
            _tradeLicense = v[2];
            _pharmacyLocation = v[3];
          }),
        );
        break;
      case _StakeholderRole.labSpecialist:
        _editSection(
          title: 'Work Info',
          labels: const ['Department', 'Location'],
          values: [_department, _labLocation],
          firestoreKeys: const ['specialty', 'pharmacyLocation'],
          onSave: (v) => setState(() {
            _department = v[0];
            _labLocation = v[1];
          }),
        );
        break;
    }
  }

  void _openAccountSheet() {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'Account',
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _ActionRow(
                  icon: Icons.notifications_outlined,
                  label: 'Notification Preferences',
                  onTap: () {},
                ),
                _ActionRow(
                  icon: Icons.lock_outline,
                  label: 'Change Password',
                  onTap: () {},
                ),
                _ActionRow(
                  icon: Icons.logout,
                  label: 'Logout',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Get.offAll(
                      () => const LoginScreen(),
                      transition: Transition.fadeIn,
                    );
                  },
                  isDestructive: true,
                  showDivider: false,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case _ProfileTab.personal:
        return _TabSectionCard(
          key: const ValueKey(_ProfileTab.personal),
          onEdit: _editPersonalInfo,
          children: [
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Name',
              value: _fullName,
            ),
            _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: _phone),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: _email,
              showDivider:
                  _role == _StakeholderRole.doctor ||
                  _role == _StakeholderRole.pharmacist,
            ),
            if (_role == _StakeholderRole.doctor)
              _InfoRow(
                icon: Icons.wc_outlined,
                label: 'Gender',
                value: _gender,
                showDivider: false,
              ),
            if (_role == _StakeholderRole.pharmacist)
              _InfoRow(
                icon: Icons.credit_card_outlined,
                label: 'NID Number',
                value: _nidNumber,
                showDivider: false,
              ),
          ],
        );
      case _ProfileTab.secondary:
        switch (_role) {
          case _StakeholderRole.doctor:
            return _TabSectionCard(
              key: const ValueKey('secondary-doctor'),
              onEdit: _editSecondaryInfo,
              children: [
                _InfoRow(
                  icon: Icons.medical_services_outlined,
                  label: 'Specialty',
                  value: _specialty,
                ),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'BMDC License',
                  value: _licenseNumber,
                  showDivider: false,
                ),
              ],
            );
          case _StakeholderRole.pharmacist:
            return _TabSectionCard(
              key: const ValueKey('secondary-pharmacist'),
              onEdit: _editSecondaryInfo,
              children: [
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Pharmacy Council Registration',
                  value: _pharmacistRegistrationNumber,
                ),
                _InfoRow(
                  icon: Icons.local_pharmacy_outlined,
                  label: 'Pharmacy Name',
                  value: _pharmacyName,
                ),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Trade License',
                  value: _tradeLicense,
                ),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Pharmacy Location',
                  value: _pharmacyLocation,
                  showDivider: false,
                ),
              ],
            );
          case _StakeholderRole.labSpecialist:
            return _TabSectionCard(
              key: const ValueKey('secondary-lab'),
              onEdit: _editSecondaryInfo,
              children: [
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Staff ID',
                  value: _staffId,
                ),
                _InfoRow(
                  icon: Icons.apartment_outlined,
                  label: 'Department',
                  value: _department,
                ),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: _labLocation,
                  showDivider: false,
                ),
              ],
            );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double pad = Sizes.responsivePadding(context);

    return Container(
      color: isDark ? const Color(0xFF181818) : Colors.white,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, pad * 0.8, pad, 120),
          children: [
            _ProfileHero(
              name: _fullName,
              idPillLabel: _idPillLabel,
              onSettingsTap: _openAccountSheet,
            ),
            SizedBox(height: pad),
            _ProfileTabBar(
              active: _activeTab,
              secondaryLabel: _secondaryTabLabel,
              onChanged: (t) => setState(() => _activeTab = t),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.idPillLabel,
    required this.onSettingsTap,
  });

  final String name;
  final String idPillLabel;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF92140C), Color(0xFF5D0B07)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: MColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -50,
            right: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            right: 30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: MColors.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 11,
                            color: MColors.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _HeroIconButton(
                    icon: Icons.settings_outlined,
                    onTap: onSettingsTap,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  idPillLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({
    required this.active,
    required this.secondaryLabel,
    required this.onChanged,
  });

  final _ProfileTab active;
  final String secondaryLabel;
  final ValueChanged<_ProfileTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F1F1F)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final _ProfileTab tab in _ProfileTab.values)
            Expanded(
              child: _ProfileTabChip(
                label: tab == _ProfileTab.personal
                    ? 'Personal'
                    : secondaryLabel,
                selected: tab == active,
                onTap: () => onChanged(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileTabChip extends StatelessWidget {
  const _ProfileTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? MColors.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabSectionCard extends StatelessWidget {
  const _TabSectionCard({super.key, required this.children, this.onEdit});

  final List<Widget> children;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onEdit != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: MColors.primaryColor,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: MColors.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color = isDestructive ? Colors.red : MColors.primaryColor;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDestructive ? Colors.red : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 14, endIndent: 14),
      ],
    );
  }
}
