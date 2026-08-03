import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
                  onPressed: () {
                    Get.snackbar(
                      'Upload stub',
                      'File picker can be connected later to Firebase Storage.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MColors.primaryColor,
                    side: const BorderSide(color: MColors.primaryColor),
                  ),
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Pick Result File'),
                ),
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
          FilledButton.icon(
            onPressed: () async {
              await LabService.instance.attachResult(
                orderId: widget.order.id,
                note: _noteController.text.trim(),
              );
              if (!context.mounted) {
                return;
              }
              Get.snackbar(
                'Result attached',
                'The order has been updated with a result note stub.',
                snackPosition: SnackPosition.BOTTOM,
              );
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: MColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Save Result Stub'),
          ),
        ],
      ),
    );
  }
}
