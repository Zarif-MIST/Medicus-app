import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/patient_lab_result_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/patient_record_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Services/doctor_service.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({super.key, required this.record});

  final PatientRecordModel record;

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  late Future<List<PatientLabResultModel>> _labResultsFuture;

  @override
  void initState() {
    super.initState();
    _labResultsFuture = DoctorService.instance.getLabResultsForPatient(
      widget.record.account.userId,
    );
  }

  String _formatDateTime(DateTime timestamp) {
    final int hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final String minute = timestamp.minute.toString().padLeft(2, '0');
    final String period = timestamp.hour < 12 ? 'AM' : 'PM';
    return '${timestamp.day} ${_months[timestamp.month - 1]} ${timestamp.year}, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final PatientRecordModel record = widget.record;
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF181818)
          : const Color(0xFFF7F5F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Patient Record'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          LiquidGlassLayer(
            settings: LiquidGlassSettings(
              thickness: 18,
              blur: 10,
              glassColor: isDark
                  ? const Color(0x26FFFFFF)
                  : const Color(0xA6FFFFFF),
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
                      MColors.primaryColor.withValues(
                        alpha: isDark ? 0.35 : 0.16,
                      ),
                      MColors.primaryColor.withValues(
                        alpha: isDark ? 0.18 : 0.06,
                      ),
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
                        _InfoChip(
                          label: 'Blood Group',
                          value: record.bloodGroup,
                          isDark: isDark,
                        ),
                        _InfoChip(
                          label: 'Allergies',
                          value: record.allergies,
                          isDark: isDark,
                        ),
                        _InfoChip(
                          label: 'Conditions',
                          value: record.chronicConditions,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Vitals', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: record.vitals.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final vital = record.vitals[index];
              return _VitalCard(vital: vital, isDark: isDark);
            },
          ),
          const SizedBox(height: 20),
          Text('Recent History', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final entry in record.history) ...[
            _HistoryCard(entry: entry, isDark: isDark),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 20),
          Text('Lab Results', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          FutureBuilder<List<PatientLabResultModel>>(
            future: _labResultsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: MColors.primaryColor,
                    ),
                  ),
                );
              }

              final List<PatientLabResultModel> results = snapshot.data!;
              if (results.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'No completed lab results for this patient yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  for (final result in results) ...[
                    _LabResultCard(
                      result: result,
                      isDark: isDark,
                      formatDateTime: _formatDateTime,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            vital.label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '${vital.value} ${vital.unit}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.isDark});

  final PatientHistoryEntry entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Text(
                entry.dateLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabResultCard extends StatelessWidget {
  const _LabResultCard({
    required this.result,
    required this.isDark,
    required this.formatDateTime,
  });

  final PatientLabResultModel result;
  final bool isDark;
  final String Function(DateTime) formatDateTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.orderType,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (result.completedAt != null)
                Text(
                  formatDateTime(result.completedAt!),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            result.requestedBy,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : const Color(0xFFF8F5F3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              (result.resultNote == null || result.resultNote!.isEmpty)
                  ? 'No result note was added for this order.'
                  : result.resultNote!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: (result.resultNote == null || result.resultNote!.isEmpty)
                    ? Colors.grey
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
          if (result.resultFileName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.attach_file,
                  size: 15,
                  color: MColors.primaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.resultFileName!,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
