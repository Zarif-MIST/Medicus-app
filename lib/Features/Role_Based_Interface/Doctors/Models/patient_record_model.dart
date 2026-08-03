import 'package:medicus/Features/Authentication/Models/auth_account.dart';

class PatientVital {
  const PatientVital({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;
}

class PatientHistoryEntry {
  const PatientHistoryEntry({
    required this.title,
    required this.subtitle,
    required this.dateLabel,
  });

  final String title;
  final String subtitle;
  final String dateLabel;
}

class PatientRecordModel {
  const PatientRecordModel({
    required this.account,
    required this.bloodGroup,
    required this.allergies,
    required this.chronicConditions,
    required this.vitals,
    required this.history,
  });

  final AuthAccount account;
  final String bloodGroup;
  final String allergies;
  final String chronicConditions;
  final List<PatientVital> vitals;
  final List<PatientHistoryEntry> history;
}
