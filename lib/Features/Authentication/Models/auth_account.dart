import 'auth_role.dart';

class AuthAccount {
  const AuthAccount({
    this.firebaseUid,
    required this.userId,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.verificationCode,
    this.specialty,
    this.gender,
    this.dateOfBirth,
    this.licenseNumber,
    this.pharmacyName,
    this.tradeLicense,
    this.nidNumber,
    this.pharmacyLocation,
    this.isVerified = false,
  });

  final String? firebaseUid;
  final String userId;
  final AuthRole role;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phoneNumber;
  final String verificationCode;
  final String? specialty;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? licenseNumber;
  final String? pharmacyName;
  final String? tradeLicense;
  final String? nidNumber;
  final String? pharmacyLocation;
  final bool isVerified;

  String get fullName => '$firstName $lastName'.trim();

  String get maskedEmail {
    final int atIndex = email.indexOf('@');
    if (atIndex <= 1) {
      return email;
    }

    return '${email.substring(0, 1)}***${email.substring(atIndex)}';
  }

  AuthAccount copyWith({
    String? firebaseUid,
    String? userId,
    AuthRole? role,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? phoneNumber,
    String? verificationCode,
    String? specialty,
    String? gender,
    DateTime? dateOfBirth,
    String? licenseNumber,
    String? pharmacyName,
    String? tradeLicense,
    String? nidNumber,
    String? pharmacyLocation,
    bool? isVerified,
  }) {
    return AuthAccount(
      firebaseUid: firebaseUid ?? this.firebaseUid,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationCode: verificationCode ?? this.verificationCode,
      specialty: specialty ?? this.specialty,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      tradeLicense: tradeLicense ?? this.tradeLicense,
      nidNumber: nidNumber ?? this.nidNumber,
      pharmacyLocation: pharmacyLocation ?? this.pharmacyLocation,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
