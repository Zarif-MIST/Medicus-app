import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/pat_dash.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/patient_profile_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';

const List<String> _kBloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

/// Shown once, right after a patient's first successful login (no
/// `patient_profiles` document exists yet for them). Collects the basics an
/// emergency responder or pharmacist would need — blood group, allergies,
/// chronic conditions — but doesn't block: "Skip for now" still lets the
/// patient in, and a reminder banner on the home screen picks up from there.
class PatientMedicalOnboardingScreen extends StatefulWidget {
  const PatientMedicalOnboardingScreen({super.key, required this.account});

  final AuthAccount account;

  @override
  State<PatientMedicalOnboardingScreen> createState() => _PatientMedicalOnboardingScreenState();
}

class _PatientMedicalOnboardingScreenState extends State<PatientMedicalOnboardingScreen> {
  static const PatientProfileService _service = PatientProfileService();

  String? _bloodGroup;
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _allergiesController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  void _continueToDashboard() {
    Get.offAll(() => PatientDashboardScreen(account: widget.account), transition: Transition.fadeIn);
  }

  Future<void> _skip() async {
    setState(() => _saving = true);
    try {
      await _service.save(
        PatientProfileRecord(
          patientId: widget.account.userId,
          phone: widget.account.phoneNumber,
          email: widget.account.email,
          medicalInfoCompleted: false,
        ),
      );
    } catch (_) {
      // Best-effort — the reminder banner will simply keep showing if this
      // write failed (e.g. offline); the patient still isn't blocked.
    }
    if (!mounted) return;
    _continueToDashboard();
  }

  Future<void> _save() async {
    if (_bloodGroup == null) {
      Get.snackbar('Select a blood group', 'This helps in an emergency.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.save(
        PatientProfileRecord(
          patientId: widget.account.userId,
          phone: widget.account.phoneNumber,
          email: widget.account.email,
          bloodGroup: _bloodGroup!,
          allergies: _allergiesController.text.trim().isEmpty ? 'None' : _allergiesController.text.trim(),
          chronicConditions: _conditionsController.text.trim().isEmpty ? 'None' : _conditionsController.text.trim(),
          medicalInfoCompleted: true,
        ),
      );
    } catch (_) {
      // Fall through and continue anyway — the profile screen lets them
      // retry this later.
    }
    if (!mounted) return;
    _continueToDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double pad = Sizes.responsivePadding(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181818) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, pad * 1.4, pad, pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.health_and_safety_outlined, color: MColors.primaryColor, size: 48),
              const SizedBox(height: 16),
              Text('Complete your medical profile', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'This helps doctors, pharmacists, and emergency responders treat you safely. You can skip and fill this in later from your profile.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Text('Blood group', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final String group in _kBloodGroups)
                    ChoiceChip(
                      label: Text(group),
                      selected: _bloodGroup == group,
                      onSelected: (_) => setState(() => _bloodGroup = group),
                      selectedColor: MColors.primaryColor,
                      labelStyle: TextStyle(
                        color: _bloodGroup == group ? Colors.white : null,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _allergiesController,
                decoration: InputDecoration(
                  labelText: 'Allergies',
                  hintText: 'e.g. Penicillin — or leave blank for None',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _conditionsController,
                decoration: InputDecoration(
                  labelText: 'Chronic conditions',
                  hintText: 'e.g. Type 2 Diabetes — or leave blank for None',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_saving ? 'Saving…' : 'Save & Continue'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _saving ? null : _skip,
                  child: const Text('Skip for now', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
