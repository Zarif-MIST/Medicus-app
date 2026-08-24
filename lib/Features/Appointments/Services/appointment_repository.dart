import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicus/Features/Appointments/Models/appointment_record.dart';

/// The single Firestore collection ('appointments') behind patient booking
/// and the doctor's appointment list — single equality filters only (on
/// patientId or doctorId), same convention as the rest of this app's reads;
/// date filtering (e.g. "today") happens client-side on the small result set.
class AppointmentRepository {
  const AppointmentRepository();

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('appointments');

  Future<String> create({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required String specialty,
    required String hospital,
    required DateTime date,
    required String time,
    required int fee,
    String windowId = '',
  }) async {
    final AppointmentRecord draft = AppointmentRecord(
      id: '',
      patientId: patientId,
      patientName: patientName,
      doctorId: doctorId,
      doctorName: doctorName,
      specialty: specialty,
      hospital: hospital,
      date: date,
      time: time,
      fee: fee,
      status: AppointmentRecord.statusConfirmed,
      createdAt: DateTime.now(),
      windowId: windowId,
    );

    final DocumentReference<Map<String, dynamic>> ref = await _collection.add(draft.toCreateJson());
    return ref.id;
  }

  /// How many patients have already booked [windowId] on [date] for
  /// [doctorId] — used to enforce that window's capacity and to show
  /// "12/20 booked" in the picker. Not transactional: two bookings racing
  /// at the exact same instant could both slip through, an accepted
  /// trade-off at this app's scale rather than adding Firestore transactions
  /// for a hard real-time guarantee.
  Future<int> countBookingsForWindow({
    required String doctorId,
    required String windowId,
    required DateTime date,
  }) async {
    if (windowId.isEmpty) return 0;
    final List<AppointmentRecord> doctorAppointments = await fetchForDoctor(doctorId);
    return doctorAppointments
        .where(
          (a) =>
              a.windowId == windowId &&
              a.date.year == date.year &&
              a.date.month == date.month &&
              a.date.day == date.day,
        )
        .length;
  }

  Future<List<AppointmentRecord>> fetchForPatient(String patientId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection.where('patientId', isEqualTo: patientId).get();
    final List<AppointmentRecord> records = snapshot.docs.map(AppointmentRecord.fromDoc).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return records;
  }

  Future<List<AppointmentRecord>> fetchForDoctor(String doctorId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection.where('doctorId', isEqualTo: doctorId).get();
    final List<AppointmentRecord> records = snapshot.docs.map(AppointmentRecord.fromDoc).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return records;
  }
}
