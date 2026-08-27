import 'package:cloud_firestore/cloud_firestore.dart';

/// The canonical, Firestore-backed appointment — written when a patient
/// books a slot, read by that patient (upcoming appointments, calendar) and
/// by the doctor (today's appointments). A direct-booked slot is considered
/// confirmed immediately; there's no separate approval step in this flow.
class AppointmentRecord {
  const AppointmentRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.hospital,
    required this.date,
    required this.time,
    required this.fee,
    required this.status,
    required this.createdAt,
    this.windowId = '',
  });

  static const String statusConfirmed = 'Confirmed';

  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String hospital;
  final DateTime date;
  final String time;
  final int fee;
  final String status;
  final DateTime createdAt;

  /// The [DoctorAvailabilityWindow] this booking was made against, if any —
  /// used to count how many patients have already booked that exact window
  /// on that exact date, so it can be closed once it hits capacity.
  final String windowId;

  Map<String, dynamic> toCreateJson() => {
    'patientId': patientId,
    'patientName': patientName,
    'doctorId': doctorId,
    'doctorName': doctorName,
    'specialty': specialty,
    'hospital': hospital,
    'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
    'time': time,
    'fee': fee,
    'status': statusConfirmed,
    'createdAt': FieldValue.serverTimestamp(),
    'windowId': windowId,
  };

  factory AppointmentRecord.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AppointmentRecord(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      doctorId: data['doctorId'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      specialty: data['specialty'] as String? ?? '',
      hospital: data['hospital'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: data['time'] as String? ?? '',
      fee: (data['fee'] as num?)?.toInt() ?? 0,
      status: data['status'] as String? ?? statusConfirmed,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      windowId: data['windowId'] as String? ?? '',
    );
  }
}
