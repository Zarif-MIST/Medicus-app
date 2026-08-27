import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/records/records_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/patient_profile_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/records/prescription.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/qr/my_qr_screen.dart';

// TODO: replace with the logged-in patient's real userId once every screen
// consistently receives a fully-populated AuthAccount — matches the mock id
// used app-wide (pharmacy, lab reports, doctor's mock patient lookup).
const String _mockPatientId = '4821';
const String _mockPatientName = 'Tareq';

String _orPlaceholder(String value) => value.trim().isEmpty ? 'Not set' : value;

enum _ProfileTab { personal, medical, emergency }

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
  const PatientProfileScreen({
    super.key,
    required this.account,
    required this.prescriptions,
  });

  final AuthAccount account;
  final List<Prescription> prescriptions;

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  static const PatientProfileService _profileService = PatientProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  String get _patientId =>
      widget.account.userId.isEmpty ? _mockPatientId : widget.account.userId;
  String get _patientName => widget.account.firstName.isEmpty
      ? _mockPatientName
      : widget.account.fullName;

  String _phone = '';
  String _email = '';
  String _address = '';
  String _dob = '';

  String _bloodGroup = '';
  String _allergies = '';
  String _chronicConditions = '';
  bool _medicalInfoCompleted = true;

  String _emergencyName = '';
  String _emergencyPhone = '';

  String? _photoBase64;
  bool _uploadingPhoto = false;

  _ProfileTab _activeTab = _ProfileTab.personal;

  @override
  void initState() {
    super.initState();
    _phone = widget.account.phoneNumber;
    _email = widget.account.email;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final PatientProfileRecord? record = await _profileService.fetch(
        _patientId,
      );
      if (!mounted || record == null) return;
      setState(() {
        _phone = record.phone.isNotEmpty
            ? record.phone
            : widget.account.phoneNumber;
        _email = record.email.isNotEmpty ? record.email : widget.account.email;
        _address = record.address;
        _dob = record.dateOfBirth;
        _bloodGroup = record.bloodGroup;
        _allergies = record.allergies;
        _chronicConditions = record.chronicConditions;
        _medicalInfoCompleted = record.medicalInfoCompleted;
        _emergencyName = record.emergencyContactName;
        _emergencyPhone = record.emergencyContactPhone;
        _photoBase64 = record.photoBase64;
      });
    } catch (_) {
      // Leave the fields at their defaults on failure (e.g. offline) — the
      // patient can still edit and the next save will create the doc.
    }
  }

  Future<void> _persistProfile() async {
    try {
      await _profileService.save(
        PatientProfileRecord(
          patientId: _patientId,
          phone: _phone,
          email: _email,
          address: _address,
          dateOfBirth: _dob,
          bloodGroup: _bloodGroup,
          allergies: _allergies,
          chronicConditions: _chronicConditions,
          emergencyContactName: _emergencyName,
          emergencyContactPhone: _emergencyPhone,
          photoBase64: _photoBase64,
          medicalInfoCompleted:
              _medicalInfoCompleted || _bloodGroup.trim().isNotEmpty,
        ),
      );
    } catch (_) {
      // Best-effort — the edited values still show locally for this session
      // even if the write failed (e.g. offline).
    }
  }

  Future<void> _pickPhoto() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final Uint8List bytes = await picked.readAsBytes();
      final String base64Photo = _profileService.compressPhotoToBase64(bytes);
      setState(() {
        _photoBase64 = base64Photo;
        _uploadingPhoto = false;
      });
      await _persistProfile();
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't upload that photo — try a smaller image."),
        ),
      );
    }
  }

  Future<void> _editSection({
    required String title,
    required List<String> labels,
    required List<String> values,
    required Future<void> Function(List<String> newValues) onSave,
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
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            bool saving = false;

            Future<void> handleSave() async {
              setSheetState(() => saving = true);
              // The values must be captured before the sheet pops, but the
              // write itself is awaited *before* popping — otherwise a quick
              // tab switch right after tapping Save could reload this
              // profile from Firestore before the edit actually landed,
              // making it look reverted.
              await onSave([for (final c in controllers) c.text.trim()]);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            }

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
                      onPressed: saving ? null : handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
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
      },
    );

    for (final c in controllers) {
      c.dispose();
    }
  }

  void _editPersonalInfo() {
    _editSection(
      title: 'Personal Info',
      labels: const ['Phone', 'Email', 'Address', 'Date of Birth'],
      values: [_phone, _email, _address, _dob],
      onSave: (v) async {
        setState(() {
          _phone = v[0];
          _email = v[1];
          _address = v[2];
          _dob = v[3];
        });
        await _persistProfile();
      },
    );
  }

  void _editMedicalInfo() {
    _editSection(
      title: 'Medical Info',
      labels: const ['Blood Group', 'Allergies', 'Chronic Conditions'],
      values: [_bloodGroup, _allergies, _chronicConditions],
      onSave: (v) async {
        setState(() {
          _bloodGroup = v[0];
          _allergies = v[1];
          _chronicConditions = v[2];
          _medicalInfoCompleted = true;
        });
        await _persistProfile();
      },
    );
  }

  void _editEmergencyContact() {
    _editSection(
      title: 'Emergency Contact',
      labels: const ['Name', 'Phone'],
      values: [_emergencyName, _emergencyPhone],
      onSave: (v) async {
        setState(() {
          _emergencyName = v[0];
          _emergencyPhone = v[1];
        });
        await _persistProfile();
      },
    );
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
                  onTap: () {},
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
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: _orPlaceholder(_phone),
            ),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: _orPlaceholder(_email),
            ),
            _InfoRow(
              icon: Icons.home_outlined,
              label: 'Address',
              value: _orPlaceholder(_address),
            ),
            _InfoRow(
              icon: Icons.cake_outlined,
              label: 'Date of Birth',
              value: _orPlaceholder(_dob),
              showDivider: false,
            ),
          ],
        );
      case _ProfileTab.medical:
        return _TabSectionCard(
          key: const ValueKey(_ProfileTab.medical),
          onEdit: _editMedicalInfo,
          children: [
            _InfoRow(
              icon: Icons.bloodtype_outlined,
              label: 'Blood Group',
              value: _orPlaceholder(_bloodGroup),
            ),
            _InfoRow(
              icon: Icons.warning_amber_outlined,
              label: 'Allergies',
              value: _orPlaceholder(_allergies),
            ),
            _InfoRow(
              icon: Icons.healing_outlined,
              label: 'Chronic Conditions',
              value: _orPlaceholder(_chronicConditions),
              showDivider: false,
            ),
          ],
        );
      case _ProfileTab.emergency:
        return _TabSectionCard(
          key: const ValueKey(_ProfileTab.emergency),
          onEdit: _editEmergencyContact,
          children: [
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Name',
              value: _orPlaceholder(_emergencyName),
            ),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: _orPlaceholder(_emergencyPhone),
              showDivider: false,
            ),
          ],
        );
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
              patientName: _patientName,
              patientId: _patientId,
              photoBase64: _photoBase64,
              uploadingPhoto: _uploadingPhoto,
              onPhotoTap: _pickPhoto,
              onQrTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MyQrScreen(
                    patientId: _patientId,
                    patientName: _patientName,
                  ),
                ),
              ),
              onSettingsTap: _openAccountSheet,
            ),
            if (!_medicalInfoCompleted) ...[
              SizedBox(height: pad * 0.6),
              _MedicalInfoReminder(
                onTap: () => setState(() => _activeTab = _ProfileTab.medical),
              ),
            ],
            SizedBox(height: pad),
            _FactChipsRow(
              bloodGroup: _orPlaceholder(_bloodGroup),
              dob: _orPlaceholder(_dob),
              allergies: _orPlaceholder(_allergies),
              chronicConditions: _orPlaceholder(_chronicConditions),
            ),
            SizedBox(height: pad),
            _ProfileTabBar(
              active: _activeTab,
              onChanged: (t) => setState(() => _activeTab = t),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildTabContent(),
            ),
            SizedBox(height: pad * 0.8),
            _NavCard(
              icon: Icons.description_outlined,
              title: 'Medical Records',
              subtitle: 'View ongoing & previous prescriptions',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecordsScreen(
                    patientId: _patientId,
                    patientName: _patientName,
                    prescriptions: widget.prescriptions,
                  ),
                ),
              ),
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
    required this.patientName,
    required this.patientId,
    required this.onQrTap,
    required this.onSettingsTap,
    this.photoBase64,
    this.uploadingPhoto = false,
    required this.onPhotoTap,
  });

  final String patientName;
  final String patientId;
  final VoidCallback onQrTap;
  final VoidCallback onSettingsTap;
  final String? photoBase64;
  final bool uploadingPhoto;
  final VoidCallback onPhotoTap;

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onPhotoTap,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                            image: photoBase64 != null
                                ? DecorationImage(
                                    image: MemoryImage(
                                      base64Decode(photoBase64!),
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: photoBase64 != null
                              ? null
                              : Text(
                                  patientName.isNotEmpty
                                      ? patientName[0].toUpperCase()
                                      : 'P',
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
                            child: uploadingPhoto
                                ? const SizedBox(
                                    width: 11,
                                    height: 11,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: MColors.primaryColor,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    size: 11,
                                    color: MColors.primaryColor,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _HeroIconButton(
                    icon: Icons.qr_code_2_rounded,
                    onTap: onQrTap,
                  ),
                  const SizedBox(width: 8),
                  _HeroIconButton(
                    icon: Icons.settings_outlined,
                    onTap: onSettingsTap,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                patientName,
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
                  'Patient ID · $patientId',
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

class _MedicalInfoReminder extends StatelessWidget {
  const _MedicalInfoReminder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Complete your medical profile — blood group, allergies, and conditions help in an emergency.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.orange),
            ],
          ),
        ),
      ),
    );
  }
}

class _FactChipsRow extends StatelessWidget {
  const _FactChipsRow({
    required this.bloodGroup,
    required this.dob,
    required this.allergies,
    required this.chronicConditions,
  });

  final String bloodGroup;
  final String dob;
  final String allergies;
  final String chronicConditions;

  @override
  Widget build(BuildContext context) {
    final List<(IconData, String, String)> items = [
      (Icons.bloodtype_outlined, 'Blood Group', bloodGroup),
      (Icons.cake_outlined, 'Date of Birth', dob),
      (Icons.warning_amber_outlined, 'Allergies', allergies),
      (Icons.healing_outlined, 'Conditions', chronicConditions),
    ];

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (icon, label, value) = items[i];
          return _FactChip(icon: icon, label: label, value: value);
        },
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Container(
      width: 132,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: MColors.primaryColor, size: 18),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({required this.active, required this.onChanged});

  final _ProfileTab active;
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
                tab: tab,
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
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _ProfileTab tab;
  final bool selected;
  final VoidCallback onTap;

  String get _label {
    switch (tab) {
      case _ProfileTab.personal:
        return 'Personal';
      case _ProfileTab.medical:
        return 'Medical';
      case _ProfileTab.emergency:
        return 'Emergency';
    }
  }

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
            _label,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: MColors.primaryColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

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
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
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
