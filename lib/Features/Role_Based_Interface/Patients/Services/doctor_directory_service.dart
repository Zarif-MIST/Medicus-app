import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/doctor_result_card.dart';

class DoctorDirectoryService {
  DoctorDirectoryService._();

  static final DoctorDirectoryService instance = DoctorDirectoryService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<DoctorSummary> _mockDoctors = [
    DoctorSummary(
      id: 'mock-kamrul-islam',
      name: 'Dr. Kamrul Islam',
      specialty: 'General',
      hospital: 'United Hospital, Dhaka',
      rating: 4.6,
      experienceYears: 8,
      fee: 500,
      nextAvailable: 'Tomorrow 10 AM',
    ),
    DoctorSummary(
      id: 'mock-farhana-rahman',
      name: 'Dr. Farhana Rahman',
      specialty: 'Cardiologist',
      hospital: 'Square Hospital, Dhaka',
      rating: 4.8,
      experienceYears: 12,
      fee: 800,
      nextAvailable: 'Today 5 PM',
    ),
    DoctorSummary(
      id: 'mock-nusrat-jahan',
      name: 'Dr. Nusrat Jahan',
      specialty: 'Dermatologist',
      hospital: 'Apollo Hospital, Dhaka',
      rating: 4.9,
      experienceYears: 15,
      fee: 1000,
      nextAvailable: 'Today 7 PM',
    ),
    DoctorSummary(
      id: 'mock-shafiul-alam',
      name: 'Dr. Shafiul Alam',
      specialty: 'Pediatrician',
      hospital: 'Dhaka Shishu Hospital',
      rating: 4.7,
      experienceYears: 10,
      fee: 600,
      nextAvailable: 'Today 6 PM',
    ),
    DoctorSummary(
      id: 'mock-mahbub-hasan',
      name: 'Dr. Mahbub Hasan',
      specialty: 'Orthopedic',
      hospital: 'Square Hospital, Dhaka',
      rating: 4.5,
      experienceYears: 14,
      fee: 900,
      nextAvailable: 'Tomorrow 11 AM',
    ),
    DoctorSummary(
      id: 'mock-sadia-afrin',
      name: 'Dr. Sadia Afrin',
      specialty: 'Dentist',
      hospital: 'Smile Dental Care',
      rating: 4.8,
      experienceYears: 9,
      fee: 700,
      nextAvailable: 'Today 4 PM',
    ),
    DoctorSummary(
      id: 'mock-rehana-begum',
      name: 'Dr. Rehana Begum',
      specialty: 'Gynecologist',
      hospital: 'LabAid Hospital, Dhaka',
      rating: 4.9,
      experienceYears: 18,
      fee: 900,
      nextAvailable: 'Tomorrow 9 AM',
    ),
    DoctorSummary(
      id: 'mock-anisur-rahman',
      name: 'Dr. Anisur Rahman',
      specialty: 'ENT',
      hospital: 'Apollo Hospital, Dhaka',
      rating: 4.6,
      experienceYears: 11,
      fee: 650,
      nextAvailable: 'Today 3 PM',
    ),
    DoctorSummary(
      id: 'mock-fahmida-sultana',
      name: 'Dr. Fahmida Sultana',
      specialty: 'Psychiatrist',
      hospital: 'United Hospital, Dhaka',
      rating: 4.7,
      experienceYears: 7,
      fee: 750,
      nextAvailable: 'Tomorrow 2 PM',
    ),
    DoctorSummary(
      id: 'mock-zahidul-karim',
      name: 'Dr. Zahidul Karim',
      specialty: 'Neurologist',
      hospital: 'Square Hospital, Dhaka',
      rating: 4.8,
      experienceYears: 16,
      fee: 1200,
      nextAvailable: 'Today 8 PM',
    ),
  ];

  Future<List<DoctorSummary>> getDoctors() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .limit(50)
          .get();

      final List<DoctorSummary> doctors = snapshot.docs
          .map((doc) => _mapDoctor(doc.id, doc.data()))
          .whereType<DoctorSummary>()
          .toList();

      if (doctors.isNotEmpty) {
        return doctors;
      }
    } catch (_) {
      // Falls back to bundled mock doctors when Firestore is unavailable.
    }

    return _mockDoctors;
  }

  DoctorSummary? _mapDoctor(String docId, Map<String, dynamic> data) {
    final String firstName = (data['firstName'] ?? '').toString().trim();
    final String lastName = (data['lastName'] ?? '').toString().trim();
    final String fullName = '$firstName $lastName'.trim();

    if (fullName.isEmpty) {
      return null;
    }

    final String specialty = (data['specialty'] ?? '').toString().trim();
    final String userId = (data['userId'] ?? '').toString().trim();
    final int avgConsultationMinutes =
        (data['avgConsultationMinutes'] as num?)?.toInt() ?? 5;

    return DoctorSummary(
      id: userId.isEmpty ? docId : userId,
      name: 'Dr. $fullName',
      specialty: specialty.isEmpty ? 'General' : specialty,
      hospital: (data['workplace'] ?? data['hospital'] ?? 'Medicus Partner Clinic')
          .toString(),
      rating: 4.7,
      experienceYears: 8,
      fee: 700,
      nextAvailable: 'Available today',
      avgConsultationMinutes: avgConsultationMinutes,
    );
  }
}
