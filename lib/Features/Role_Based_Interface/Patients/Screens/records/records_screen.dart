import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/common/app_search_bar.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/records/prescription.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/prescription_pdf.dart';

// TODO: replace with the logged-in patient's AuthAccount, same mock pattern
// used by patient_home_screen.dart and patient_profile_screen.dart.
const String _mockPatientId = '4821';
const String _mockPatientName = 'Tareq';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key, required this.prescriptions});

  final List<Prescription> prescriptions;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String _query = '';

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
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, pad * 0.6, pad, pad),
          children: [
            AppSearchBar(
              hintText: 'Search by medicine or doctor',
              onChanged: (value) => setState(() => _query = value),
            ),
            SizedBox(height: pad),
            Text('Ongoing Prescriptions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 14),
            if (ongoing.isEmpty)
              _EmptyState(text: 'No ongoing prescriptions right now.')
            else
              for (int i = 0; i < ongoing.length; i++) ...[
                if (i != 0) const SizedBox(height: 10),
                _PrescriptionCard(prescription: ongoing[i]),
              ],
            SizedBox(height: pad),
            Text('Previous Prescriptions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 14),
            if (previous.isEmpty)
              _EmptyState(text: 'No previous prescriptions on record.')
            else
              for (int i = 0; i < previous.length; i++) ...[
                if (i != 0) const SizedBox(height: 10),
                _PrescriptionCard(prescription: previous[i]),
              ],
          ],
        ),
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.prescription});

  final Prescription prescription;

  String get _formattedDate =>
      '${prescription.date.day.toString().padLeft(2, '0')}/${prescription.date.month.toString().padLeft(2, '0')}/${prescription.date.year}';

  Future<void> _viewPdf(BuildContext context) async {
    await Printing.layoutPdf(
      onLayout: (_) => buildPrescriptionPdf(
        prescription: prescription,
        patientName: _mockPatientName,
        patientId: _mockPatientId,
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
