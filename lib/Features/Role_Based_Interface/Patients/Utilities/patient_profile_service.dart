import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;

/// A patient's own profile data — personal, medical, and emergency-contact
/// details plus an optional photo. One document per patient, keyed by the
/// same `patientId` (the AuthAccount `userId`) used everywhere else.
class PatientProfileRecord {
  const PatientProfileRecord({
    required this.patientId,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.dateOfBirth = '',
    this.bloodGroup = '',
    this.allergies = '',
    this.chronicConditions = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.photoBase64,
    this.medicalInfoCompleted = false,
  });

  final String patientId;
  final String phone;
  final String email;
  final String address;
  final String dateOfBirth;
  final String bloodGroup;
  final String allergies;
  final String chronicConditions;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String? photoBase64;
  final bool medicalInfoCompleted;

  Uint8List? get photoBytes => photoBase64 == null ? null : base64Decode(photoBase64!);

  factory PatientProfileRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PatientProfileRecord(
      patientId: doc.id,
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      address: data['address'] as String? ?? '',
      dateOfBirth: data['dateOfBirth'] as String? ?? '',
      bloodGroup: data['bloodGroup'] as String? ?? '',
      allergies: data['allergies'] as String? ?? '',
      chronicConditions: data['chronicConditions'] as String? ?? '',
      emergencyContactName: data['emergencyContactName'] as String? ?? '',
      emergencyContactPhone: data['emergencyContactPhone'] as String? ?? '',
      photoBase64: data['photoBase64'] as String?,
      medicalInfoCompleted: data['medicalInfoCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'email': email,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      if (photoBase64 != null) 'photoBase64': photoBase64,
      'medicalInfoCompleted': medicalInfoCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  PatientProfileRecord copyWith({
    String? phone,
    String? email,
    String? address,
    String? dateOfBirth,
    String? bloodGroup,
    String? allergies,
    String? chronicConditions,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? photoBase64,
    bool? medicalInfoCompleted,
  }) {
    return PatientProfileRecord(
      patientId: patientId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      photoBase64: photoBase64 ?? this.photoBase64,
      medicalInfoCompleted: medicalInfoCompleted ?? this.medicalInfoCompleted,
    );
  }
}

/// Thrown when a picked profile photo can't be compressed under
/// [PatientProfileService.maxEncodedBytes].
class ProfilePhotoTooLargeException implements Exception {
  const ProfilePhotoTooLargeException();
}

/// Firestore-backed CRUD for [PatientProfileRecord] — one document per
/// patient, doc id == patientId, so a fetch/save is a direct `.doc()` lookup
/// rather than a query.
class PatientProfileService {
  const PatientProfileService();

  /// Firestore documents are capped at ~1 MiB; stay well under that once
  /// base64 overhead (~33%) and the rest of the profile fields are added.
  static const int maxEncodedBytes = 700 * 1024;

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('patient_profiles');

  Future<PatientProfileRecord?> fetch(String patientId) async {
    if (patientId.isEmpty) return null;
    final doc = await _collection.doc(patientId).get();
    if (!doc.exists) return null;
    return PatientProfileRecord.fromDoc(doc);
  }

  Future<void> save(PatientProfileRecord record) async {
    await _collection.doc(record.patientId).set(record.toMap(), SetOptions(merge: true));
  }

  String compressPhotoToBase64(Uint8List rawBytes) {
    final img.Image? decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      throw const ProfilePhotoTooLargeException();
    }

    for (final int maxDimension in [800, 500, 350]) {
      final img.Image resized = decoded.width > maxDimension || decoded.height > maxDimension
          ? img.copyResize(
              decoded,
              width: decoded.width >= decoded.height ? maxDimension : null,
              height: decoded.height > decoded.width ? maxDimension : null,
            )
          : decoded;

      for (final int quality in [70, 50, 35]) {
        final Uint8List encoded = img.encodeJpg(resized, quality: quality);
        final String base64Str = base64Encode(encoded);
        if (base64Str.length <= maxEncodedBytes) {
          return base64Str;
        }
      }
    }

    throw const ProfilePhotoTooLargeException();
  }
}
