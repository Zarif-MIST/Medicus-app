import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicus/Features/Prescriptions/Models/prescription_record.dart';
import 'package:medicus/Features/Prescriptions/Services/prescription_repository.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Models/lab_order_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Services/lab_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class LabResultUploadScreen extends StatefulWidget {
  const LabResultUploadScreen({super.key, required this.order});

  final LabOrderModel order;

  @override
  State<LabResultUploadScreen> createState() => _LabResultUploadScreenState();
}

class _LabResultUploadScreenState extends State<LabResultUploadScreen> {
  static const PrescriptionRepository _prescriptionRepository = PrescriptionRepository();

  final TextEditingController _noteController = TextEditingController();
  String? _selectedFileName;
  bool _saving = false;
  late final Future<PrescriptionRecord?> _linkedPrescriptionFuture = widget.order.prescriptionId.isEmpty
      ? Future.value(null)
      : _prescriptionRepository.fetchById(widget.order.prescriptionId);

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final PlatformFile? file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (file == null) {
      return;
    }
    setState(() => _selectedFileName = file.name);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await LabService.instance.attachResult(
        orderId: widget.order.id,
        note: _noteController.text.trim(),
        fileName: _selectedFileName,
      );
      if (!mounted) {
        return;
      }
      Get.snackbar(
        'Result attached',
        'The order has been updated for ${widget.order.patientName}.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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
        title: const Text('Attach Result'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.order.patientName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.order.orderType,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MColors.primaryColor,
                    side: const BorderSide(color: MColors.primaryColor),
                  ),
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    _selectedFileName == null
                        ? 'Pick Result File'
                        : 'Change File',
                  ),
                ),
                if (_selectedFileName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _selectedFileName!,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Add result notes or summary',
                    filled: true,
                    fillColor: isDark
                        ? Colors.white10
                        : const Color(0xFFF8F5F3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _LinkedPrescriptionCard(future: _linkedPrescriptionFuture, isDark: isDark),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: MColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.upload_file_outlined),
            label: Text(_saving ? 'Saving...' : 'Save Result'),
          ),
        ],
      ),
    );
  }
}

/// Shows the prescription this order was requested from, if any, so the
/// specialist can see why the test was ordered before filing the result —
/// and so the result stays attached to that exact prescription for the
/// patient's and the requesting doctor's records.
class _LinkedPrescriptionCard extends StatelessWidget {
  const _LinkedPrescriptionCard({required this.future, required this.isDark});

  final Future<PrescriptionRecord?> future;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PrescriptionRecord?>(
      future: future,
      builder: (context, snapshot) {
        final PrescriptionRecord? prescription = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting || prescription == null) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : const Color(0xFFF8F5F3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MColors.primaryColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 16, color: MColors.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'Requested from this prescription',
                    style: theme.textTheme.bodySmall?.copyWith(color: MColors.primaryColor, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Dr. ${prescription.doctorName}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (prescription.diagnosis.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(prescription.diagnosis, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
              if (prescription.medicines.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  prescription.medicines.map((m) => m.name).join(', '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
