import 'package:flutter/material.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/common/app_search_bar.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/records/prescription.dart';

enum _SortMode { byDate, byDoctor }

/// The "See all" destination from the home prescription section — every
/// medicine a doctor has prescribed. A patient with many prescriptions needs
/// to actually find one, so this searches across doctor name, medicine name,
/// and date, and lets them choose how the list is organized: a flat
/// newest-first timeline, or grouped by doctor.
class PrescriptionMedicinesScreen extends StatefulWidget {
  const PrescriptionMedicinesScreen({super.key, required this.prescriptions});

  final List<Prescription> prescriptions;

  @override
  State<PrescriptionMedicinesScreen> createState() =>
      _PrescriptionMedicinesScreenState();
}

class _PrescriptionMedicinesScreenState
    extends State<PrescriptionMedicinesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _SortMode _sortMode = _SortMode.byDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Prescription> get _sortedByRecency {
    final list = List.of(widget.prescriptions);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  String _formattedDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  List<Prescription> get _filtered {
    final String q = _query.trim().toLowerCase();
    final List<Prescription> sorted = _sortedByRecency;
    if (q.isEmpty) return sorted;

    return sorted.where((p) {
      if (p.doctorName.toLowerCase().contains(q)) return true;
      if (_formattedDate(p.date).contains(q)) return true;
      return p.medicines.any((m) => m.name.toLowerCase().contains(q));
    }).toList();
  }

  /// Groups [prescriptions] by doctor, each group's own prescriptions kept
  /// newest-first, and the groups themselves ordered by whichever doctor's
  /// most recent visit is most recent.
  List<MapEntry<String, List<Prescription>>> _groupedByDoctor(
    List<Prescription> prescriptions,
  ) {
    final Map<String, List<Prescription>> byDoctor = {};
    for (final Prescription p in prescriptions) {
      (byDoctor[p.doctorName] ??= []).add(p);
    }
    final List<MapEntry<String, List<Prescription>>> entries =
        byDoctor.entries.toList()
          ..sort((a, b) => b.value.first.date.compareTo(a.value.first.date));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double pad = Sizes.responsivePadding(context);
    final theme = Theme.of(context);
    final bool hasAny = widget.prescriptions.isNotEmpty;
    final List<Prescription> visible = _filtered;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181818) : Colors.white,
      appBar: AppBar(title: const Text('Prescribed Medicines')),
      body: SafeArea(
        child: !hasAny
            ? Center(
                child: Text(
                  'No medicines have been prescribed yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, pad * 0.6, pad, 0),
                    child: AppSearchBar(
                      hintText: 'Search by doctor, medicine, or date',
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
                    child: Row(
                      children: [
                        Text(
                          'Sort by',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _SortChip(
                          label: 'Date',
                          selected: _sortMode == _SortMode.byDate,
                          onTap: () =>
                              setState(() => _sortMode = _SortMode.byDate),
                        ),
                        const SizedBox(width: 8),
                        _SortChip(
                          label: 'Doctor',
                          selected: _sortMode == _SortMode.byDoctor,
                          onTap: () =>
                              setState(() => _sortMode = _SortMode.byDoctor),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: visible.isEmpty
                        ? Center(
                            child: Text(
                              'No prescriptions match "${_query.trim()}".',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : _sortMode == _SortMode.byDate
                        ? ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              pad,
                              pad * 0.6,
                              pad,
                              pad * 2,
                            ),
                            itemCount: visible.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: pad * 0.7),
                            itemBuilder: (context, index) => _PrescriptionGroup(
                              prescription: visible[index],
                              isDark: isDark,
                              formattedDate: _formattedDate(
                                visible[index].date,
                              ),
                            ),
                          )
                        : _DoctorGroupedList(
                            groups: _groupedByDoctor(visible),
                            isDark: isDark,
                            pad: pad,
                            formattedDate: _formattedDate,
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: MColors.primaryColor,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _DoctorGroupedList extends StatelessWidget {
  const _DoctorGroupedList({
    required this.groups,
    required this.isDark,
    required this.pad,
    required this.formattedDate,
  });

  final List<MapEntry<String, List<Prescription>>> groups;
  final bool isDark;
  final double pad;
  final String Function(DateTime) formattedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(pad, pad * 0.6, pad, pad * 2),
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final MapEntry<String, List<Prescription>> group = groups[groupIndex];
        return Padding(
          padding: EdgeInsets.only(bottom: pad * 0.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.key,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${group.value.length} prescription${group.value.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (int i = 0; i < group.value.length; i++) ...[
                if (i != 0) SizedBox(height: pad * 0.7),
                _PrescriptionGroup(
                  prescription: group.value[i],
                  isDark: isDark,
                  formattedDate: formattedDate(group.value[i].date),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PrescriptionGroup extends StatelessWidget {
  const _PrescriptionGroup({
    required this.prescription,
    required this.isDark,
    required this.formattedDate,
  });

  final Prescription prescription;
  final bool isDark;
  final String formattedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
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
                child: Text(
                  prescription.doctorName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                formattedDate,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < prescription.medicines.length; i++) ...[
            if (i != 0) const Divider(height: 20),
            _MedicineRow(medicine: prescription.medicines[i], isDark: isDark),
          ],
        ],
      ),
    );
  }
}

class _MedicineRow extends StatelessWidget {
  const _MedicineRow({required this.medicine, required this.isDark});

  final PrescriptionMedicine medicine;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: MColors.primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.medication_outlined,
            color: MColors.primaryColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medicine.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(medicine.dosage, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                '${medicine.durationDays}-day course',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
