import 'package:medicus/Features/Authentication/Services/auth_registry.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/pharmacies/pharmacy.dart';

/// Reads the patient-facing pharmacy directory straight out of pharmacist
/// registrations — there is no separate `pharmacies` collection, a
/// registered pharmacist account *is* a pharmacy listing.
class PharmacyRegistryService {
  const PharmacyRegistryService();

  Future<List<RegisteredPharmacy>> fetchAllPharmacies() async {
    final accounts = await AuthRegistry.instance.pharmacistAccounts();
    return [
      for (final account in accounts) ?RegisteredPharmacy.fromAuthAccount(account),
    ];
  }
}
