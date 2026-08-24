import 'package:cloud_firestore/cloud_firestore.dart';

const List<String> kWeekdayFullNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

/// Formats a doctor-entered "HH:mm" 24-hour string as a 12-hour clock label
/// (e.g. "16:00" -> "4:00 PM") without needing a BuildContext/localizations —
/// used both in UI labels and in plain repository/logic code.
String formatClockTime(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return hhmm;
  final int? hour = int.tryParse(parts[0]);
  final int? minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return hhmm;

  final String period = hour >= 12 ? 'PM' : 'AM';
  final int hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}

/// A recurring weekly slot a doctor has made themselves available in — e.g.
/// "every Monday, 4:00 PM to 6:00 PM, up to 20 patients". Patients booking
/// pick from that doctor's windows for the weekday matching their chosen
/// date; the window closes once [capacity] appointments exist for it on
/// that specific date.
class DoctorAvailabilityWindow {
  const DoctorAvailabilityWindow({
    required this.id,
    required this.doctorId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.capacity,
  });

  final String id;
  final String doctorId;

  /// 1 = Monday ... 7 = Sunday, matching [DateTime.weekday].
  final int weekday;
  final String startTime;
  final String endTime;
  final int capacity;

  String get label => '${formatClockTime(startTime)} - ${formatClockTime(endTime)}';
  String get weekdayName => kWeekdayFullNames[weekday - 1];

  Map<String, dynamic> toJson() => {
        'doctorId': doctorId,
        'weekday': weekday,
        'startTime': startTime,
        'endTime': endTime,
        'capacity': capacity,
      };

  factory DoctorAvailabilityWindow.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return DoctorAvailabilityWindow(
      id: doc.id,
      doctorId: data['doctorId'] as String? ?? '',
      weekday: (data['weekday'] as num?)?.toInt() ?? 1,
      startTime: data['startTime'] as String? ?? '00:00',
      endTime: data['endTime'] as String? ?? '00:00',
      capacity: (data['capacity'] as num?)?.toInt() ?? 20,
    );
  }
}
