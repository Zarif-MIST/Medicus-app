import 'package:medicus/Features/Authentication/Services/auth_registry.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/doctor_result_card.dart';

/// Reads the patient-facing doctor directory straight out of doctor
/// registrations — there is no separate `doctors` collection, a registered
/// doctor account *is* a directory listing. Mirrors [PharmacyRegistryService].
class DoctorDirectoryService {
  const DoctorDirectoryService();

  Future<List<DoctorSummary>> fetchAllDoctors() async {
    final accounts = await AuthRegistry.instance.doctorAccounts();
    return [for (final account in accounts) DoctorSummary.fromAuthAccount(account)];
  }
}
