import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicus/Features/Appointments/Models/doctor_availability_window.dart';

/// A doctor's self-managed recurring weekly availability — single equality
/// filter on `doctorId`, same convention as the rest of this app's reads.
class DoctorAvailabilityRepository {
  const DoctorAvailabilityRepository();

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('doctor_availability');

  Future<void> create({
    required String doctorId,
    required int weekday,
    required String startTime,
    required String endTime,
    required int capacity,
  }) async {
    await _collection.add(
      DoctorAvailabilityWindow(
        id: '',
        doctorId: doctorId,
        weekday: weekday,
        startTime: startTime,
        endTime: endTime,
        capacity: capacity,
      ).toJson(),
    );
  }

  Future<List<DoctorAvailabilityWindow>> fetchForDoctor(String doctorId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection
        .where('doctorId', isEqualTo: doctorId)
        .get();
    final List<DoctorAvailabilityWindow> windows =
        snapshot.docs.map(DoctorAvailabilityWindow.fromDoc).toList()
          ..sort((a, b) {
            final int weekdayCompare = a.weekday.compareTo(b.weekday);
            return weekdayCompare != 0
                ? weekdayCompare
                : a.startTime.compareTo(b.startTime);
          });
    return windows;
  }

  Future<void> delete(String windowId) => _collection.doc(windowId).delete();
}
