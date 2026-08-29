import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Prescriptions/Models/prescription_record.dart';
import 'package:medicus/Features/Prescriptions/Services/prescription_repository.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/patient_record_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/prescription_form_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Models/lab_order_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Services/lab_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/lab_report_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/common/app_search_bar.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

/// A patient's full record from the doctor's side — reached by searching a
/// patient ID or scanning their QR. Two tabs: History (every uploaded report
/// and past prescription on file, newest first, each showing its date and
/// doctor) and Prescribe (write a new one right here).
class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({super.key, required this.record, required this.doctor});

  final PatientRecordModel record;
  final AuthAccount doctor;

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  /// Bumping this forces the History tab's FutureBuilder-backed sections to
  /// recreate (via the ValueKey below) and refetch — used right after a new
  /// prescription is saved from the Prescribe tab.
  int _historyRefreshKey = 0;

  void _onPrescriptionSaved() {
    setState(() => _historyRefreshKey++);
    _tabController.animateTo(0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);
    final PatientRecordModel record = widget.record;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181818) : const Color(0xFFF7F5F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Patient Record'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  LiquidGlassLayer(
                    settings: LiquidGlassSettings(
                      thickness: 18,
                      blur: 10,
                      glassColor: isDark ? const Color(0x26FFFFFF) : const Color(0xA6FFFFFF),
                      lightIntensity: 1.1,
                      saturation: 1.15,
                      refractiveIndex: 1.25,
                    ),
                    child: LiquidGlass(
                      shape: LiquidRoundedSuperellipse(borderRadius: 28),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              MColors.primaryColor.withValues(alpha: isDark ? 0.35 : 0.16),
                              MColors.primaryColor.withValues(alpha: isDark ? 0.18 : 0.06),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.account.fullName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Patient ID: ${record.account.userId}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _InfoChip(label: 'Blood Group', value: record.bloodGroup, isDark: isDark),
                                _InfoChip(label: 'Allergies', value: record.allergies, isDark: isDark),
                                _InfoChip(label: 'Conditions', value: record.chronicConditions, isDark: isDark),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: record.vitals.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemBuilder: (context, index) => _VitalCard(vital: record.vitals[index], isDark: isDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              labelColor: MColors.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: MColors.primaryColor,
              tabs: const [
                Tab(text: 'History'),
                Tab(text: 'Prescribe'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _HistoryTab(
                    key: ValueKey(_historyRefreshKey),
                    patientId: record.account.userId,
                    isDark: isDark,
                    doctor: widget.doctor,
                  ),
                  PrescriptionFormBody(
                    doctor: widget.doctor,
                    patient: record,
                    onSaved: _onPrescriptionSaved,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends StatefulWidget {
  const _HistoryTab({super.key, required this.patientId, required this.isDark, required this.doctor});

  final String patientId;
  final bool isDark;
  final AuthAccount doctor;

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  String _query = '';
  late final Future<List<LabOrderModel>> _labOrdersFuture =
      LabService.instance.getAllOrdersForPatient(widget.patientId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        AppSearchBar(
          hintText: 'Search prescriptions by medicine or doctor',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 20),
        Text('Reports', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        _UploadedReportsSection(patientId: widget.patientId, isDark: widget.isDark),
        const SizedBox(height: 24),
        Text('Prescriptions', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Ongoing and previous courses, with any linked lab test shown under its prescription — same grouping the patient sees.',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 10),
        _PrescriptionHistorySection(
          patientId: widget.patientId,
          isDark: widget.isDark,
          query: _query,
          doctor: widget.doctor,
          labOrdersFuture: _labOrdersFuture,
        ),
      ],
    );
  }
}

class _UploadedReportsSection extends StatefulWidget {
  const _UploadedReportsSection({required this.patientId, required this.isDark});

  final String patientId;
  final bool isDark;

  @override
  State<_UploadedReportsSection> createState() => _UploadedReportsSectionState();
}

class _UploadedReportsSectionState extends State<_UploadedReportsSection> {
  static const LabReportService _service = LabReportService();
  late final Future<List<LabReport>> _reportsFuture = _service.fetchForPatient(widget.patientId);

  void _view(LabReport report) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(report.label)),
          body: Center(child: InteractiveViewer(child: Image.memory(report.imageBytes))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LabReport>>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: MColors.primaryColor)),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Could not load reports.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          );
        }
        final List<LabReport> reports = snapshot.data ?? const [];
        if (reports.isEmpty) {
          return Text(
            'No reports uploaded by this patient yet.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          );
        }
        return SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: reports.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final LabReport report = reports[index];
              return GestureDetector(
                onTap: () => _view(report),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 120,
                    color: widget.isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: Image.memory(report.imageBytes, fit: BoxFit.cover)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Text(
                            report.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PrescriptionHistorySection extends StatefulWidget {
  const _PrescriptionHistorySection({
    required this.patientId,
    required this.isDark,
    required this.doctor,
    required this.labOrdersFuture,
    this.query = '',
  });

  final String patientId;
  final bool isDark;
  final AuthAccount doctor;
  final Future<List<LabOrderModel>> labOrdersFuture;
  final String query;

  @override
  State<_PrescriptionHistorySection> createState() => _PrescriptionHistorySectionState();
}

class _PrescriptionHistorySectionState extends State<_PrescriptionHistorySection> {
  static const PrescriptionRepository _repository = PrescriptionRepository();
  late final Future<List<PrescriptionRecord>> _future = _repository.fetchForPatient(widget.patientId);

  List<PrescriptionRecord> _sortedByRecency(List<PrescriptionRecord> records) {
    final list = [...records];
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Object>>(
      future: Future.wait([_future, widget.labOrdersFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: MColors.primaryColor)),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Could not load prescriptions.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          );
        }

        final List<PrescriptionRecord> all = snapshot.data![0] as List<PrescriptionRecord>;
        final List<LabOrderModel> allOrders = snapshot.data![1] as List<LabOrderModel>;
        final Map<String, List<LabOrderModel>> byPrescription = {};
        final List<LabOrderModel> unlinked = [];
        for (final order in allOrders) {
          if (order.prescriptionId.isEmpty) {
            unlinked.add(order);
          } else {
            (byPrescription[order.prescriptionId] ??= []).add(order);
          }
        }

        final String query = widget.query.trim().toLowerCase();
        final List<PrescriptionRecord> filtered = query.isEmpty
            ? all
            : all.where((record) {
                final bool matchesDoctor = record.doctorName.toLowerCase().contains(query);
                final bool matchesMedicine = record.medicines.any(
                  (medicine) => medicine.name.toLowerCase().contains(query),
                );
                return matchesDoctor || matchesMedicine;
              }).toList();

        final List<PrescriptionRecord> ongoing = _sortedByRecency(filtered.where((r) => !r.isCompleted).toList());
        final List<PrescriptionRecord> previous = _sortedByRecency(filtered.where((r) => r.isCompleted).toList());

        if (filtered.isEmpty) {
          return Text(
            query.isEmpty
                ? 'No prescriptions on file for this patient yet.'
                : 'No prescriptions match "$query".',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ongoing', style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 10),
            if (ongoing.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('None right now.', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              )
            else
              for (final PrescriptionRecord record in ongoing) ...[
                _PrescriptionHistoryCard(
                  record: record,
                  isDark: widget.isDark,
                  doctor: widget.doctor,
                  labTests: byPrescription[record.id] ?? const [],
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 12),
            Text('Previous', style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 10),
            if (previous.isEmpty)
              Text('None on file.', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey))
            else
              for (final PrescriptionRecord record in previous) ...[
                _PrescriptionHistoryCard(
                  record: record,
                  isDark: widget.isDark,
                  doctor: widget.doctor,
                  labTests: byPrescription[record.id] ?? const [],
                ),
                const SizedBox(height: 12),
              ],
            if (unlinked.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Other Lab Tests', style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey)),
              const SizedBox(height: 10),
              for (final LabOrderModel order in unlinked) ...[
                _LabTestTile(order: order, isDark: widget.isDark),
                const SizedBox(height: 8),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _LabTestTile extends StatelessWidget {
  const _LabTestTile({required this.order, required this.isDark});

  final LabOrderModel order;
  final bool isDark;

  bool get _isCompleted => order.status == 'Completed';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF8F5F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, size: 16, color: MColors.primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.orderType,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (_isCompleted ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    color: _isCompleted ? Colors.green.shade700 : Colors.orange.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (_isCompleted && (order.resultNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(order.resultNote!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)),
          ],
        ],
      ),
    );
  }
}

class _PrescriptionHistoryCard extends StatelessWidget {
  const _PrescriptionHistoryCard({
    required this.record,
    required this.isDark,
    required this.doctor,
    this.labTests = const [],
  });

  final PrescriptionRecord record;
  final bool isDark;
  final AuthAccount doctor;
  final List<LabOrderModel> labTests;

  String _formattedDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _orderLabTest(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    final String? testName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Order Lab Test'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Complete Blood Count'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Order'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (testName == null || testName.isEmpty) {
      return;
    }

    await LabService.instance.createOrder(
      patientId: record.patientId,
      patientName: record.patientName,
      orderType: testName,
      requestedBy: doctor.fullName,
      prescriptionId: record.id,
    );

    if (!context.mounted) {
      return;
    }
    Get.snackbar(
      'Lab test ordered',
      '$testName requested for ${record.patientName}.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.doctorName,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(_formattedDate(record.createdAt), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ),
          if (record.diagnosis.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(record.diagnosis, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
          const SizedBox(height: 12),
          for (int i = 0; i < record.medicines.length; i++) ...[
            if (i != 0) const Divider(height: 18),
            _MedicineLine(medicine: record.medicines[i]),
          ],
          if (labTests.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final LabOrderModel order in labTests) ...[
              _LabTestTile(order: order, isDark: isDark),
              const SizedBox(height: 6),
            ],
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _orderLabTest(context),
              icon: const Icon(Icons.science_outlined, size: 16, color: MColors.primaryColor),
              label: const Text('Order Lab Test', style: TextStyle(color: MColors.primaryColor, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineLine extends StatelessWidget {
  const _MedicineLine({required this.medicine});

  final PrescriptionRecordMedicine medicine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.medication_outlined, color: MColors.primaryColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(medicine.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(
                '${medicine.dosage} · ${medicine.durationDays}-day course',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  const _VitalCard({required this.vital, required this.isDark});

  final PatientVital vital;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            vital.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '${vital.value} ${vital.unit}'.trim(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
