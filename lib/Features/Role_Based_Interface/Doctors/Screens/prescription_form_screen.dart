import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/doctor_prescription_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/patient_record_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Services/doctor_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class PrescriptionFormScreen extends StatefulWidget {
  const PrescriptionFormScreen({
    super.key,
    required this.doctor,
    required this.patient,
  });

  final AuthAccount doctor;
  final PatientRecordModel patient;

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final List<_MedicineDraft> _medicines = <_MedicineDraft>[_MedicineDraft()];

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    for (final medicine in _medicines) {
      medicine.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final DoctorPrescriptionModel prescription = DoctorPrescriptionModel(
      patientId: widget.patient.account.userId,
      doctorId: widget.doctor.userId,
      specialty: widget.doctor.specialty ?? 'General Physician',
      diagnosis: _diagnosisController.text.trim(),
      medicines: _medicines
          .where((medicine) => medicine.name.text.trim().isNotEmpty)
          .map(
            (medicine) => DoctorPrescriptionMedicine(
              name: medicine.name.text.trim(),
              dosage: medicine.dosage.text.trim(),
              instructions: medicine.instructions.text.trim(),
            ),
          )
          .toList(),
      additionalNotes: _notesController.text.trim(),
      specialtyExtras: const <String, String>{},
    );

    await DoctorService.instance.savePrescription(prescription);
    if (!mounted) {
      return;
    }
    Get.snackbar(
      'Prescription saved',
      'Prescription drafted for ${widget.patient.account.fullName}.',
      snackPosition: SnackPosition.BOTTOM,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF181818)
          : const Color(0xFFF7F5F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Write Prescription'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _FormCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patient.account.fullName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Specialty: ${widget.doctor.specialty ?? 'General Physician'}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FormCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diagnosis',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _diagnosisController,
                    minLines: 3,
                    maxLines: 5,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter diagnosis notes'
                        : null,
                    decoration: _inputDecoration(
                      context,
                      'Enter diagnosis or clinical impression',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FormCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Medicines',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _medicines.add(_MedicineDraft())),
                        icon: const Icon(
                          Icons.add,
                          color: MColors.primaryColor,
                        ),
                        label: const Text(
                          'Add',
                          style: TextStyle(color: MColors.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < _medicines.length; i++) ...[
                    _MedicineFields(
                      draft: _medicines[i],
                      index: i,
                      isDark: isDark,
                      onRemove: _medicines.length == 1
                          ? null
                          : () => setState(() {
                              _medicines[i].dispose();
                              _medicines.removeAt(i);
                            }),
                    ),
                    if (i != _medicines.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FormCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Notes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: _inputDecoration(
                      context,
                      'Advice, investigations, or follow-up instructions',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Specialty-specific fields can later be added through specialtyExtras without changing this base form.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: MColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Prescription'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineDraft {
  _MedicineDraft()
    : name = TextEditingController(),
      dosage = TextEditingController(),
      instructions = TextEditingController();

  final TextEditingController name;
  final TextEditingController dosage;
  final TextEditingController instructions;

  void dispose() {
    name.dispose();
    dosage.dispose();
    instructions.dispose();
  }
}

class _MedicineFields extends StatelessWidget {
  const _MedicineFields({
    required this.draft,
    required this.index,
    required this.isDark,
    required this.onRemove,
  });

  final _MedicineDraft draft;
  final int index;
  final bool isDark;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF8F5F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Medicine ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.grey,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: draft.name,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter medicine name'
                : null,
            decoration: _inputDecoration(context, 'Medicine name'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: draft.dosage,
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter dosage' : null,
            decoration: _inputDecoration(context, 'Dosage'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: draft.instructions,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter instructions'
                : null,
            decoration: _inputDecoration(context, 'Instructions'),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

InputDecoration _inputDecoration(BuildContext context, String hintText) {
  final bool isDark = MHelperFunctions.isDarkMode(context);

  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: isDark ? Colors.white10 : const Color(0xFFF8F5F3),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: MColors.primaryColor),
    ),
  );
}
