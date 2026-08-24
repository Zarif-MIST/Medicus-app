import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medicus/Features/Appointments/Models/doctor_availability_window.dart';
import 'package:medicus/Features/Appointments/Services/doctor_availability_repository.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

/// Where a doctor defines the recurring weekly windows patients can book
/// into — e.g. "every Monday, 4-6 PM, up to 20 patients". Patients only ever
/// see (and can only book) what's configured here; there's no fallback to
/// a generic time-slot list.
class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({super.key, required this.doctor});

  final AuthAccount doctor;

  @override
  State<DoctorAvailabilityScreen> createState() => _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  static const DoctorAvailabilityRepository _repository = DoctorAvailabilityRepository();

  late Future<List<DoctorAvailabilityWindow>> _windowsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _windowsFuture = _repository.fetchForDoctor(widget.doctor.userId));
  }

  Future<void> _deleteWindow(DoctorAvailabilityWindow window) async {
    await _repository.delete(window.id);
    _load();
  }

  Future<void> _openAddWindowSheet() async {
    int weekday = DateTime.monday;
    TimeOfDay startTime = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 12, minute: 0);
    final TextEditingController capacityController = TextEditingController(text: '20');

    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> pickStart() async {
              final TimeOfDay? picked = await showTimePicker(context: sheetContext, initialTime: startTime);
              if (picked != null) setSheetState(() => startTime = picked);
            }

            Future<void> pickEnd() async {
              final TimeOfDay? picked = await showTimePicker(context: sheetContext, initialTime: endTime);
              if (picked != null) setSheetState(() => endTime = picked);
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
                  Text('Add availability window', style: Theme.of(sheetContext).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Text('Day of week', style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: weekday,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: [
                      for (int i = 0; i < kWeekdayFullNames.length; i++)
                        DropdownMenuItem(value: i + 1, child: Text(kWeekdayFullNames[i])),
                    ],
                    onChanged: (value) => setSheetState(() => weekday = value ?? weekday),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: pickStart,
                          child: Text('Start: ${startTime.format(sheetContext)}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: pickEnd,
                          child: Text('End: ${endTime.format(sheetContext)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Patient capacity for this window',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final int startMinutes = startTime.hour * 60 + startTime.minute;
                        final int endMinutes = endTime.hour * 60 + endTime.minute;
                        if (endMinutes <= startMinutes) {
                          Get.snackbar('Invalid window', 'End time must be after start time.', snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        final int? capacity = int.tryParse(capacityController.text.trim());
                        if (capacity == null || capacity <= 0) {
                          Get.snackbar('Invalid capacity', 'Enter a patient capacity greater than 0.', snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        Navigator.of(sheetContext).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Save window'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (saved == true) {
      final int capacity = int.tryParse(capacityController.text.trim()) ?? 20;
      await _repository.create(
        doctorId: widget.doctor.userId,
        weekday: weekday,
        startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
        capacity: capacity,
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181818) : const Color(0xFFF7F5F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Availability'),
        actions: [
          IconButton(onPressed: _openAddWindowSheet, icon: const Icon(Icons.add)),
        ],
      ),
      body: FutureBuilder<List<DoctorAvailabilityWindow>>(
        future: _windowsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: MColors.primaryColor));
          }

          final List<DoctorAvailabilityWindow> windows = snapshot.data!;
          if (windows.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "You haven't set any availability windows yet. Tap + to add one — patients can only book times you've opened up.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: windows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final DoctorAvailabilityWindow window = windows[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(window.weekdayName, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            '${window.label} · up to ${window.capacity} patients',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteWindow(window),
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
