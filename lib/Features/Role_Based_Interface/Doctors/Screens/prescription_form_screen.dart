import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/doctor_prescription_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/patient_record_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Services/doctor_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Services/lab_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

/// Standalone full-screen entry point — used by the "Write Rx" action on a
/// scheduled appointment. Wraps [PrescriptionFormBody] with its own
/// AppBar/Scaffold and pops on save.
class PrescriptionFormScreen extends StatelessWidget {
  const PrescriptionFormScreen({
    super.key,
    required this.doctor,
    required this.patient,
  });

  final AuthAccount doctor;
  final PatientRecordModel patient;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181818) : const Color(0xFFF7F5F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Write Prescription'),
      ),
      body: PrescriptionFormBody(
        doctor: doctor,
        patient: patient,
        onSaved: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// The prescription-writing form itself — no Scaffold/AppBar, so it can be
/// embedded either as [PrescriptionFormScreen]'s body or directly inside a
/// tab (see the "Prescribe" tab on [PatientDetailScreen]). Calls [onSaved]
/// once the prescription is written; the caller decides what that means
/// (pop the screen, switch tabs, refresh a list, etc).
class PrescriptionFormBody extends StatefulWidget {
  const PrescriptionFormBody({
    super.key,
    required this.doctor,
    required this.patient,
    required this.onSaved,
  });

  final AuthAccount doctor;
  final PatientRecordModel patient;
  final VoidCallback onSaved;

  @override
  State<PrescriptionFormBody> createState() => _PrescriptionFormBodyState();
}

class _PrescriptionFormBodyState extends State<PrescriptionFormBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _labTestController = TextEditingController();
  final List<_MedicineDraft> _medicines = <_MedicineDraft>[_MedicineDraft()];

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    _labTestController.dispose();
    for (final medicine in _medicines) {
      medicine.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final List<_MedicineDraft> namedMedicines =
        _medicines.where((medicine) => medicine.name.text.trim().isNotEmpty).toList();
    if (namedMedicines.any((medicine) => medicine.doseTimes.isEmpty)) {
      Get.snackbar(
        'Add dose times',
        'Every medicine needs at least one time of day so it appears on the patient\'s dose schedule.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final DoctorPrescriptionModel prescription = DoctorPrescriptionModel(
      patientId: widget.patient.account.userId,
      patientName: widget.patient.account.fullName,
      doctorId: widget.doctor.userId,
      doctorName: widget.doctor.fullName,
      specialty: widget.doctor.specialty ?? 'General Physician',
      diagnosis: _diagnosisController.text.trim(),
      medicines: namedMedicines
          .map(
            (medicine) => DoctorPrescriptionMedicine(
              name: medicine.name.text.trim(),
              dosage: medicine.dosage.text.trim(),
              instructions: medicine.instructions.text.trim(),
              durationDays: int.tryParse(medicine.durationDays.text.trim()) ?? 0,
              doseTimes: [
                for (final t in medicine.doseTimes) '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
              ],
            ),
          )
          .toList(),
      additionalNotes: _notesController.text.trim(),
      specialtyExtras: const <String, String>{},
    );

    String rxId;
    try {
      rxId = await DoctorService.instance.savePrescription(prescription);
    } catch (e) {
      if (!mounted) return;
      Get.snackbar('Could not save prescription', '$e', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final String labTest = _labTestController.text.trim();
    if (labTest.isNotEmpty) {
      await LabService.instance.createOrder(
        patientId: widget.patient.account.userId,
        patientName: widget.patient.account.fullName,
        orderType: labTest,
        requestedBy: widget.doctor.fullName,
        prescriptionId: rxId,
      );
    }

    if (!mounted) {
      return;
    }
    Get.snackbar(
      'Prescription saved',
      '$rxId issued for ${widget.patient.account.fullName} — visible in their app now.',
      snackPosition: SnackPosition.BOTTOM,
    );
    _formKey.currentState?.reset();
    _diagnosisController.clear();
    _notesController.clear();
    _labTestController.clear();
    for (final medicine in _medicines) {
      medicine.dispose();
    }
    setState(() {
      _medicines
        ..clear()
        ..add(_MedicineDraft());
    });
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Form(
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
                    'Recommend a Lab Test (optional)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _labTestController,
                    decoration: _inputDecoration(
                      context,
                      'e.g. Complete Blood Count, Lipid Profile',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leave blank if no test is needed. If filled, this creates a lab order linked to this prescription — the patient sees it in Medical Records and a lab specialist can attach results to it.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
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
    );
  }
}

class _MedicineDraft {
  _MedicineDraft()
    : name = TextEditingController(),
      dosage = TextEditingController(),
      instructions = TextEditingController(),
      durationDays = TextEditingController();

  final TextEditingController name;
  final TextEditingController dosage;
  final TextEditingController instructions;
  final TextEditingController durationDays;
  final List<TimeOfDay> doseTimes = [];

  void dispose() {
    name.dispose();
    dosage.dispose();
    instructions.dispose();
    durationDays.dispose();
  }
}

class _MedicineFields extends StatefulWidget {
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
  State<_MedicineFields> createState() => _MedicineFieldsState();
}

class _MedicineFieldsState extends State<_MedicineFields> {
  Future<void> _addTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked == null) return;

    final bool alreadyAdded = widget.draft.doseTimes.any((t) => t.hour == picked.hour && t.minute == picked.minute);
    if (alreadyAdded) return;

    setState(() {
      widget.draft.doseTimes.add(picked);
      widget.draft.doseTimes.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    });
  }

  void _removeTime(TimeOfDay time) {
    setState(() => widget.draft.doseTimes.remove(time));
  }

  @override
  Widget build(BuildContext context) {
    final _MedicineDraft draft = widget.draft;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white10 : const Color(0xFFF8F5F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Medicine ${widget.index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (widget.onRemove != null)
                IconButton(
                  onPressed: widget.onRemove,
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
          const SizedBox(height: 10),
          TextFormField(
            controller: draft.durationDays,
            keyboardType: TextInputType.number,
            validator: (value) {
              final int? parsed = int.tryParse(value?.trim() ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Enter course length in days';
              }
              return null;
            },
            decoration: _inputDecoration(context, 'Duration (days)'),
          ),
          const SizedBox(height: 10),
          Text('Dose times', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final TimeOfDay time in draft.doseTimes)
                Chip(
                  label: Text(time.format(context)),
                  labelStyle: const TextStyle(color: MColors.primaryColor, fontWeight: FontWeight.w600),
                  backgroundColor: MColors.primaryColor.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  onDeleted: () => _removeTime(time),
                  deleteIconColor: MColors.primaryColor,
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16, color: MColors.primaryColor),
                label: const Text('Add time', style: TextStyle(color: MColors.primaryColor)),
                backgroundColor: Colors.transparent,
                side: BorderSide(color: MColors.primaryColor.withValues(alpha: 0.4)),
                onPressed: _addTime,
              ),
            ],
          ),
          if (draft.doseTimes.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Add at least one time so this shows up on the patient\'s dose schedule.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
              ),
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
