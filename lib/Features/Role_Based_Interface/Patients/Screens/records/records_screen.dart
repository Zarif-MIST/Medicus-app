import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Models/lab_order_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Services/lab_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/lab_report_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/common/app_search_bar.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/records/prescription.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/prescription_pdf.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key, required this.patientId, required this.patientName, required this.prescriptions});

  final String patientId;
  final String patientName;
  final List<Prescription> prescriptions;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String _query = '';
  late final Future<List<LabOrderModel>> _labOrdersFuture =
      LabService.instance.getAllOrdersForPatient(widget.patientId);
  static const LabReportService _reportService = LabReportService();
  late final Future<List<LabReport>> _reportsFuture = _reportService.fetchForPatient(widget.patientId);

  List<Prescription> _sortedByRecency(List<Prescription> prescriptions) {
    final list = List.of(prescriptions);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double pad = Sizes.responsivePadding(context);
    final theme = Theme.of(context);

    final String query = _query.toLowerCase();
    final List<Prescription> filtered = query.isEmpty
        ? widget.prescriptions
        : widget.prescriptions.where((p) {
            final matchesDoctor = p.doctorName.toLowerCase().contains(query);
            final matchesMedicine = p.medicines.any((m) => m.name.toLowerCase().contains(query));
            return matchesDoctor || matchesMedicine;
          }).toList();

    final List<Prescription> ongoing = _sortedByRecency(filtered.where((p) => !p.isCompleted).toList());
    final List<Prescription> previous = _sortedByRecency(filtered.where((p) => p.isCompleted).toList());

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181818) : Colors.white,
      appBar: AppBar(title: const Text('Medical Records')),
      body: SafeArea(
        child: FutureBuilder<List<LabOrderModel>>(
          future: _labOrdersFuture,
          builder: (context, snapshot) {
            final List<LabOrderModel> allOrders = snapshot.data ?? const [];
            final Map<String, List<LabOrderModel>> byPrescription = {};
            final List<LabOrderModel> unlinked = [];
            for (final order in allOrders) {
              if (order.prescriptionId.isEmpty) {
                unlinked.add(order);
              } else {
                (byPrescription[order.prescriptionId] ??= []).add(order);
              }
            }

            return ListView(
              padding: EdgeInsets.fromLTRB(pad, pad * 0.6, pad, pad),
              children: [
                AppSearchBar(
                  hintText: 'Search by medicine or doctor',
                  onChanged: (value) => setState(() => _query = value),
                ),
                SizedBox(height: pad),
                Text('Uploaded Reports', style: theme.textTheme.titleMedium),
                const SizedBox(height: 14),
                _UploadedReportsSection(future: _reportsFuture, isDark: isDark),
                SizedBox(height: pad),
                Text('Ongoing Prescriptions', style: theme.textTheme.titleMedium),
                const SizedBox(height: 14),
                if (ongoing.isEmpty)
                  _EmptyState(text: 'No ongoing prescriptions right now.')
                else
                  for (int i = 0; i < ongoing.length; i++) ...[
                    if (i != 0) const SizedBox(height: 10),
                    _PrescriptionCard(
                      prescription: ongoing[i],
                      patientId: widget.patientId,
                      patientName: widget.patientName,
                      labTests: byPrescription[ongoing[i].id] ?? const [],
                    ),
                  ],
                SizedBox(height: pad),
                Text('Previous Prescriptions', style: theme.textTheme.titleMedium),
                const SizedBox(height: 14),
                if (previous.isEmpty)
                  _EmptyState(text: 'No previous prescriptions on record.')
                else
                  for (int i = 0; i < previous.length; i++) ...[
                    if (i != 0) const SizedBox(height: 10),
                    _PrescriptionCard(
                      prescription: previous[i],
                      patientId: widget.patientId,
                      patientName: widget.patientName,
                      labTests: byPrescription[previous[i].id] ?? const [],
                    ),
                  ],
                if (unlinked.isNotEmpty) ...[
                  SizedBox(height: pad),
                  Text('Other Lab Tests', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 14),
                  for (int i = 0; i < unlinked.length; i++) ...[
                    if (i != 0) const SizedBox(height: 10),
                    _LabTestTile(order: unlinked[i], isDark: isDark),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({
    required this.prescription,
    required this.patientId,
    required this.patientName,
    this.labTests = const [],
  });

  final Prescription prescription;
  final String patientId;
  final String patientName;
  final List<LabOrderModel> labTests;

  String get _formattedDate =>
      '${prescription.date.day.toString().padLeft(2, '0')}/${prescription.date.month.toString().padLeft(2, '0')}/${prescription.date.year}';

  Future<void> _viewPdf(BuildContext context) async {
    await Printing.layoutPdf(
      onLayout: (_) => buildPrescriptionPdf(
        prescription: prescription,
        patientName: patientName,
        patientId: patientId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(prescription.id, style: theme.textTheme.titleSmall?.copyWith(color: MColors.primaryColor)),
              ),
              Text(_formattedDate, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 2),
          Text(prescription.doctorName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (final medicine in prescription.medicines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${medicine.name} — ${medicine.dosage} (${medicine.durationDays}d)',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
              ),
            ),
          if (labTests.isNotEmpty) ...[
            const SizedBox(height: 4),
            const Divider(height: 18),
            Text('Lab Tests', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (final order in labTests) ...[
              _LabTestTile(order: order, isDark: isDark),
              const SizedBox(height: 6),
            ],
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _viewPdf(context),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: MColors.primaryColor),
              label: const Text('View PDF', style: TextStyle(color: MColors.primaryColor, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadedReportsSection extends StatelessWidget {
  const _UploadedReportsSection({required this.future, required this.isDark});

  final Future<List<LabReport>> future;
  final bool isDark;

  void _view(BuildContext context, LabReport report) {
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
      future: future,
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
            'No reports uploaded yet.',
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
                onTap: () => _view(context, report),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 120,
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
      ),
    );
  }
}
