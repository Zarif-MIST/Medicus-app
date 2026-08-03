import 'package:medicus/Features/Authentication/Models/auth_account.dart';

/// A pharmacy, sourced from a pharmacist's own registration in this app
/// (Firestore `users` collection, filtered to role == pharmacist) — not a
/// third-party directory.
class RegisteredPharmacy {
  const RegisteredPharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
  });

  /// Builds from a pharmacist [AuthAccount]. Returns null if the account is
  /// missing a pinned location (registered before location capture existed,
  /// or hasn't updated their profile yet).
  static RegisteredPharmacy? fromAuthAccount(AuthAccount account) {
    if (account.pharmacyLat == null || account.pharmacyLng == null || account.firebaseUid == null) {
      return null;
    }

    return RegisteredPharmacy(
      id: account.firebaseUid!,
      name: (account.pharmacyName?.trim().isNotEmpty ?? false) ? account.pharmacyName! : 'Unnamed Pharmacy',
      address: account.pharmacyLocation ?? '',
      phone: account.phoneNumber,
      lat: account.pharmacyLat!,
      lng: account.pharmacyLng!,
    );
  }

  final String id;
  final String name;
  final String address;
  final String phone;
  final double lat;
  final double lng;
}

/// A [RegisteredPharmacy] paired with its live distance from the patient.
class NearbyPharmacy {
  const NearbyPharmacy({required this.pharmacy, required this.distanceMeters});

  final RegisteredPharmacy pharmacy;
  final double distanceMeters;

  String get distanceLabel {
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
}
