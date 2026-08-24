import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/doctor_result_card.dart';

class AppointmentService {
  AppointmentService._();

  static final AppointmentService instance = AppointmentService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<BookedAppointment> bookAppointment({
    required AuthAccount patient,
    required DoctorSummary doctor,
    required DateTime date,
    required String time,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'patientId': patient.userId,
      'patientName': patient.fullName,
      'doctorId': doctor.id,
      'doctorName': doctor.name,
      'specialty': doctor.specialty,
      'hospital': doctor.hospital,
      'date': Timestamp.fromDate(date),
      'time': time,
      'fee': doctor.fee,
      'reason': 'General Consultation',
      'status': 'upcoming',
      'createdAt': FieldValue.serverTimestamp(),
    };

    final DocumentReference<Map<String, dynamic>> doc = await _firestore
        .collection('appointments')
        .add(payload);

    return BookedAppointment(
      id: doc.id,
      patientId: patient.userId,
      doctorId: doctor.id,
      doctorName: doctor.name,
      specialty: doctor.specialty,
      hospital: doctor.hospital,
      date: date,
      time: time,
      fee: doctor.fee,
      status: 'upcoming',
    );
  }

  /// Time labels already booked with this doctor on [date] — used to keep
  /// two patients from picking the same clinic slot.
  Future<Set<String>> getBookedTimesForDoctor({
    required String doctorId,
    required DateTime date,
  }) async {
    final DateTime startOfDay = DateTime(date.year, date.month, date.day);
    final DateTime startOfNextDay = startOfDay.add(const Duration(days: 1));

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(startOfNextDay))
        .get();

    return {
      for (final doc in snapshot.docs)
        if ((doc.data()['time'] as String?)?.isNotEmpty ?? false)
          doc.data()['time'] as String,
    };
  }

  Future<List<BookedAppointment>> getUpcomingAppointments(
    String patientId,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('date')
        .get();

    return [
      for (final doc in snapshot.docs) _fromFirestore(doc.id, doc.data()),
    ];
  }

  BookedAppointment _fromFirestore(String id, Map<String, dynamic> data) {
    return BookedAppointment(
      id: id,
      patientId: (data['patientId'] ?? '') as String,
      doctorId: (data['doctorId'] ?? '') as String,
      doctorName: (data['doctorName'] ?? '') as String,
      specialty: (data['specialty'] ?? '') as String,
      hospital: (data['hospital'] ?? '') as String,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: (data['time'] ?? '') as String,
      fee: (data['fee'] as num?)?.toInt() ?? 0,
      status: (data['status'] ?? 'upcoming') as String,
    );
  }
}
