import 'package:flutter/material.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/records/records_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/records/prescription.dart';

// TODO: replace with the logged-in patient's AuthAccount once this screen
// receives it from PatientDashboardScreen (same mock pattern as
// patient_home_screen.dart).
const String _mockPatientId = '4821';
const String _mockPatientName = 'Tareq';

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

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key, required this.prescriptions});

  final List<Prescription> prescriptions;

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  String _phone = '+880 1XXX-XXXXXX';
  String _email = 'tareq@example.com';
  String _address = 'Dhanmondi, Dhaka';
  String _dob = '12 Mar 1998';

  String _bloodGroup = 'O+';
  String _allergies = 'Penicillin';
  String _chronicConditions = 'Type 2 Diabetes';

  String _emergencyName = 'Rafiq Hasan (Brother)';
  String _emergencyPhone = '+880 1YYY-YYYYYY';

  Future<void> _editSection({
    required String title,
    required List<String> labels,
    required List<String> values,
    required void Function(List<String> newValues) onSave,
  }) async {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final controllers = [for (final v in values) TextEditingController(text: v)];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              Text('Edit $title', style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 16),
              for (int i = 0; i < labels.length; i++) ...[
                TextField(
                  controller: controllers[i],
                  decoration: InputDecoration(
                    labelText: labels[i],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onSave([for (final c in controllers) c.text.trim()]);
                    Navigator.of(sheetContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editPersonalInfo() {
    _editSection(
      title: 'Personal Info',
      labels: const ['Phone', 'Email', 'Address', 'Date of Birth'],
      values: [_phone, _email, _address, _dob],
      onSave: (v) => setState(() {
        _phone = v[0];
        _email = v[1];
        _address = v[2];
        _dob = v[3];
      }),
    );
  }

  void _editMedicalInfo() {
    _editSection(
      title: 'Medical Info',
      labels: const ['Blood Group', 'Allergies', 'Chronic Conditions'],
      values: [_bloodGroup, _allergies, _chronicConditions],
      onSave: (v) => setState(() {
        _bloodGroup = v[0];
        _allergies = v[1];
        _chronicConditions = v[2];
      }),
    );
  }

  void _editEmergencyContact() {
    _editSection(
      title: 'Emergency Contact',
      labels: const ['Name', 'Phone'],
      values: [_emergencyName, _emergencyPhone],
      onSave: (v) => setState(() {
        _emergencyName = v[0];
        _emergencyPhone = v[1];
      }),
    );
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
            _ProfileHeader(patientName: _mockPatientName, patientId: _mockPatientId),
            SizedBox(height: pad),
            _SectionCard(
              title: 'Personal Info',
              onEdit: _editPersonalInfo,
              children: [
                _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: _phone),
                _InfoRow(icon: Icons.email_outlined, label: 'Email', value: _email),
                _InfoRow(icon: Icons.home_outlined, label: 'Address', value: _address),
                _InfoRow(icon: Icons.cake_outlined, label: 'Date of Birth', value: _dob, showDivider: false),
              ],
            ),
            SizedBox(height: pad * 0.6),
            _SectionCard(
              title: 'Medical Info',
              onEdit: _editMedicalInfo,
              children: [
                _InfoRow(icon: Icons.bloodtype_outlined, label: 'Blood Group', value: _bloodGroup),
                _InfoRow(icon: Icons.warning_amber_outlined, label: 'Allergies', value: _allergies),
                _InfoRow(
                  icon: Icons.healing_outlined,
                  label: 'Chronic Conditions',
                  value: _chronicConditions,
                  showDivider: false,
                ),
              ],
            ),
            SizedBox(height: pad * 0.6),
            _SectionCard(
              title: 'Emergency Contact',
              onEdit: _editEmergencyContact,
              children: [
                _InfoRow(icon: Icons.person_outline, label: 'Name', value: _emergencyName),
                _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: _emergencyPhone, showDivider: false),
              ],
            ),
            SizedBox(height: pad * 0.6),
            _NavCard(
              icon: Icons.description_outlined,
              title: 'Medical Records',
              subtitle: 'View ongoing & previous prescriptions',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RecordsScreen(prescriptions: widget.prescriptions)),
              ),
            ),
            SizedBox(height: pad * 0.6),
            Text('Account', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Container(
              decoration: _cardDecoration(isDark),
              child: Column(
                children: [
                  _ActionRow(icon: Icons.notifications_outlined, label: 'Notification Preferences', onTap: () {}),
                  _ActionRow(icon: Icons.lock_outline, label: 'Change Password', onTap: () {}),
                  _ActionRow(icon: Icons.logout, label: 'Logout', onTap: () {}, isDestructive: true, showDivider: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.patientName, required this.patientId});

  final String patientName;
  final String patientId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MColors.primaryColor.withValues(alpha: 0.16),
            MColors.primaryColor.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: MColors.primaryColor.withValues(alpha: 0.15),
                child: const Icon(Icons.person, color: MColors.primaryColor, size: 34),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: MColors.primaryColor, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patientName, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  'Patient ID: $patientId',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children, this.onEdit});

  final String title;
  final List<Widget> children;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            if (onEdit != null)
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined, size: 18, color: MColors.primaryColor),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: _cardDecoration(isDark),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.showDivider = true});

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
                child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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

class _NavCard extends StatelessWidget {
  const _NavCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(isDark),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: MColors.primaryColor.withValues(alpha: 0.12),
                child: Icon(icon, color: MColors.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
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
