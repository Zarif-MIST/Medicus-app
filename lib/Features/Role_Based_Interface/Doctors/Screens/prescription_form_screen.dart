import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/doctor_prescription_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/patient_record_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Services/doctor_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Models/lab_order_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Services/lab_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

const List<String> _commonMedicineNames = [
  'Metformin 500mg',
  'Amoxicillin 250mg',
  'Cetirizine 10mg',
  'Ibuprofen 400mg',
  'Vitamin B Complex',
  'Omeprazole 20mg',
  'Paracetamol 500mg',
  'Salbutamol Inhaler',
  'Amlodipine 5mg',
];

const List<String> _commonDosages = [
  '1 tablet',
  '1 capsule',
  '2 tablets',
  '500mg',
  '250mg',
  '10ml',
  '5ml',
];

const List<String> _commonDurations = ['3', '5', '7', '10', '14', '30'];

const List<String> _commonInstructions = [
  'Take after meals',
  'Take before meals',
  'Take with water',
  'Take at bedtime',
  'Avoid driving',
  'Take as directed',
];

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
  String? _selectedLabTest;
  final List<_MedicineDraft> _medicines = <_MedicineDraft>[_MedicineDraft()];
  List<String> _knownMedicineNames = _commonMedicineNames;

  @override
  void initState() {
    super.initState();
    _loadKnownMedicineNames();
  }

  Future<void> _loadKnownMedicineNames() async {
    try {
      final List<String> names = await DoctorService.instance.getKnownMedicineNames();
      if (mounted && names.isNotEmpty) {
        setState(() => _knownMedicineNames = names);
      }
    } catch (_) {
      // Keep the static fallback list if inventory can't be loaded.
    }
  }

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

    final String labTest = _selectedLabTest ?? '';
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
    for (final medicine in _medicines) {
      medicine.dispose();
    }
    setState(() {
      _selectedLabTest = null;
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
                  Text(
                    'Leave blank for a lab-test-only visit with no medicine.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < _medicines.length; i++) ...[
                    _MedicineFields(
                      draft: _medicines[i],
                      index: i,
                      isDark: isDark,
                      medicineNameSuggestions: _knownMedicineNames,
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
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLabTest,
                    items: kLabTestTypes
                        .map(
                          (String testType) => DropdownMenuItem<String>(
                            value: testType,
                            child: Text(testType),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) =>
                        setState(() => _selectedLabTest = value),
                    decoration: _inputDecoration(context, 'Select a test type'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leave unselected if no test is needed. If selected, this creates a lab order linked to this prescription — the patient sees it in Medical Records and a lab specialist can attach results to it.',
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

  /// True when the doctor hasn't touched any field on this row yet — a
  /// completely untouched row is skipped from validation entirely, so a
  /// prescription can be saved with zero medicines (e.g. lab-test-only
  /// visits) instead of being blocked by the default empty row.
  bool get isBlank =>
      name.text.trim().isEmpty &&
      dosage.text.trim().isEmpty &&
      instructions.text.trim().isEmpty &&
      durationDays.text.trim().isEmpty;

  final FocusNode nameFocus = FocusNode();
  final FocusNode dosageFocus = FocusNode();
  final FocusNode instructionsFocus = FocusNode();
  final FocusNode durationDaysFocus = FocusNode();

  void dispose() {
    name.dispose();
    dosage.dispose();
    instructions.dispose();
    durationDays.dispose();
    nameFocus.dispose();
    dosageFocus.dispose();
    instructionsFocus.dispose();
    durationDaysFocus.dispose();
  }
}

class _MedicineFields extends StatefulWidget {
  const _MedicineFields({
    required this.draft,
    required this.index,
    required this.isDark,
    required this.medicineNameSuggestions,
    required this.onRemove,
  });

  final _MedicineDraft draft;
  final int index;
  final bool isDark;
  final List<String> medicineNameSuggestions;
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
          _SuggestingTextFormField(
            controller: draft.name,
            focusNode: draft.nameFocus,
            suggestions: widget.medicineNameSuggestions,
            showAllOnFocus: true,
            validator: (value) {
              if (draft.isBlank) return null;
              return value == null || value.trim().isEmpty
                  ? 'Enter medicine name'
                  : null;
            },
            decoration: _inputDecoration(context, 'Medicine name'),
          ),
          const SizedBox(height: 10),
          _SuggestingTextFormField(
            controller: draft.dosage,
            focusNode: draft.dosageFocus,
            suggestions: _commonDosages,
            validator: (value) {
              if (draft.isBlank) return null;
              return value == null || value.trim().isEmpty
                  ? 'Enter dosage'
                  : null;
            },
            decoration: _inputDecoration(context, 'Dosage'),
          ),
          const SizedBox(height: 10),
          _SuggestingTextFormField(
            controller: draft.instructions,
            focusNode: draft.instructionsFocus,
            suggestions: _commonInstructions,
            validator: (value) {
              if (draft.isBlank) return null;
              return value == null || value.trim().isEmpty
                  ? 'Enter instructions'
                  : null;
            },
            decoration: _inputDecoration(context, 'Instructions'),
          ),
          const SizedBox(height: 10),
          _SuggestingTextFormField(
            controller: draft.durationDays,
            focusNode: draft.durationDaysFocus,
            suggestions: _commonDurations,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (draft.isBlank) return null;
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

/// A [TextFormField] that offers a dropdown of matching [suggestions] as
/// the doctor types — speeds up entry of common medicine names, dosages,
/// instructions, and durations without forcing a fixed list.
class _SuggestingTextFormField extends StatelessWidget {
  const _SuggestingTextFormField({
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    required this.decoration,
    this.validator,
    this.keyboardType,
    this.showAllOnFocus = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> suggestions;
  final InputDecoration decoration;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  /// When true, tapping the field with no text yet shows every suggestion
  /// (scrollable) instead of waiting for the user to start typing.
  final bool showAllOnFocus;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue value) {
        final String query = value.text.trim().toLowerCase();
        if (query.isEmpty) {
          return showAllOnFocus ? suggestions : const Iterable<String>.empty();
        }
        return suggestions.where((s) => s.toLowerCase().contains(query));
      },
      fieldViewBuilder: (context, fieldController, fieldFocusNode, onFieldSubmitted) {
        return TextFormField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          keyboardType: keyboardType,
          validator: validator,
          decoration: decoration,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final bool isDark = MHelperFunctions.isDarkMode(context);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, minWidth: 220),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
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
