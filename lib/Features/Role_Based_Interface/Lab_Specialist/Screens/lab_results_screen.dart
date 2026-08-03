import 'package:flutter/material.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class LabResultsScreen extends StatelessWidget {
  const LabResultsScreen({super.key});

  static const List<_PatientLabResult> _results = [
    _PatientLabResult(
      patientName: 'Tareq Hasan',
      patientId: '4821',
      testName: 'CBC + Blood Sugar',
      reportId: 'RPT-801',
      collectedAt: '28 Jul 2026, 09:20 AM',
      reviewedBy: 'Dr. Farhana Rahman',
      status: 'Ready',
      findings: [
        _LabFinding(
          label: 'Hemoglobin',
          value: '13.8 g/dL',
          note: 'Within normal adult range.',
        ),
        _LabFinding(
          label: 'WBC Count',
          value: '7,400 /uL',
          note: 'No acute infection marker found.',
        ),
        _LabFinding(
          label: 'Platelet Count',
          value: '245,000 /uL',
          note: 'Normal platelet level.',
        ),
        _LabFinding(
          label: 'Fasting Blood Sugar',
          value: '102 mg/dL',
          note: 'Slightly above ideal fasting range.',
        ),
      ],
    ),
    _PatientLabResult(
      patientName: 'Nafis Ahmed',
      patientId: '6108',
      testName: 'Chest X-Ray',
      reportId: 'RPT-802',
      collectedAt: '28 Jul 2026, 11:05 AM',
      reviewedBy: 'Dr. Nusrat Jahan',
      status: 'Review Needed',
      findings: [
        _LabFinding(
          label: 'Lung Fields',
          value: 'Mild haziness',
          note: 'Patchy opacity noted in lower right zone.',
        ),
        _LabFinding(
          label: 'Cardiac Silhouette',
          value: 'Normal size',
          note: 'No cardiomegaly visible.',
        ),
        _LabFinding(
          label: 'Pleural Space',
          value: 'Clear',
          note: 'No pleural effusion detected.',
        ),
        _LabFinding(
          label: 'Impression',
          value: 'Follow-up advised',
          note: 'Clinical correlation recommended by physician.',
        ),
      ],
    ),
  ];

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
        title: const Text('Lab Results'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          _ResultsHeader(totalReports: _results.length, isDark: isDark),
          const SizedBox(height: 16),
          for (final result in _results) ...[
            _PatientResultTile(result: result, isDark: isDark),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.totalReports, required this.isDark});

  final int totalReports;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MColors.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: MColors.primaryColor.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.biotech_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Patient Lab Findings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalReports reports ready for review',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientResultTile extends StatelessWidget {
  const _PatientResultTile({required this.result, required this.isDark});

  final _PatientLabResult result;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color surfaceColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final Color mutedColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: MColors.primaryColor,
          collapsedIconColor: MColors.primaryColor,
          leading: CircleAvatar(
            backgroundColor: MColors.primaryColor.withValues(alpha: 0.14),
            child: const Icon(
              Icons.person_search_outlined,
              color: MColors.primaryColor,
            ),
          ),
          title: Text(
            result.patientName,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${result.testName} - ${result.status}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: mutedColor),
            ),
          ),
          children: [
            _ResultMetaGrid(result: result, mutedColor: mutedColor),
            const SizedBox(height: 14),
            for (final finding in result.findings) ...[
              _FindingLine(finding: finding, isDark: isDark),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultMetaGrid extends StatelessWidget {
  const _ResultMetaGrid({required this.result, required this.mutedColor});

  final _PatientLabResult result;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MetaLine(
          label: 'Patient ID',
          value: result.patientId,
          mutedColor: mutedColor,
        ),
        _MetaLine(
          label: 'Report ID',
          value: result.reportId,
          mutedColor: mutedColor,
        ),
        _MetaLine(
          label: 'Collected',
          value: result.collectedAt,
          mutedColor: mutedColor,
        ),
        _MetaLine(
          label: 'Reviewed By',
          value: result.reviewedBy,
          mutedColor: mutedColor,
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.label,
    required this.value,
    required this.mutedColor,
  });

  final String label;
  final String value;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: mutedColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FindingLine extends StatelessWidget {
  const _FindingLine({required this.finding, required this.isDark});

  final _LabFinding finding;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF8F5F3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              color: MColors.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${finding.label}: ${finding.value}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  finding.note,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientLabResult {
  const _PatientLabResult({
    required this.patientName,
    required this.patientId,
    required this.testName,
    required this.reportId,
    required this.collectedAt,
    required this.reviewedBy,
    required this.status,
    required this.findings,
  });

  final String patientName;
  final String patientId;
  final String testName;
  final String reportId;
  final String collectedAt;
  final String reviewedBy;
  final String status;
  final List<_LabFinding> findings;
}

class _LabFinding {
  const _LabFinding({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;
}
