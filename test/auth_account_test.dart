import 'package:flutter_test/flutter_test.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Authentication/Models/auth_role.dart';

AuthAccount buildAccount({
  String firstName = 'Tareq',
  String lastName = 'Rahman',
  String email = 'tareq@example.com',
  AuthRole role = AuthRole.patient,
  int? avgConsultationMinutes,
  String? clinicStartTime,
  String? clinicEndTime,
}) {
  return AuthAccount(
    userId: '4821',
    role: role,
    firstName: firstName,
    lastName: lastName,
    email: email,
    password: 'not-a-real-password',
    phoneNumber: '01700000000',
    verificationCode: '123456',
    avgConsultationMinutes: avgConsultationMinutes,
    clinicStartTime: clinicStartTime,
    clinicEndTime: clinicEndTime,
  );
}

void main() {
  group('fullName', () {
    test('joins the first and last name', () {
      expect(buildAccount().fullName, 'Tareq Rahman');
    });

    test('does not leave a dangling space when the last name is empty', () {
      expect(buildAccount(lastName: '').fullName, 'Tareq');
    });
  });

  group('maskedEmail', () {
    test('keeps the first character and the domain', () {
      expect(
        buildAccount(email: 'tareq@example.com').maskedEmail,
        't***@example.com',
      );
    });

    test('returns a single-character local part unchanged', () {
      // Masking a 1-character local part would leak nothing but also read
      // oddly, so the model deliberately passes it through.
      expect(buildAccount(email: 'a@example.com').maskedEmail, 'a@example.com');
    });

    test('returns a value with no @ unchanged', () {
      expect(buildAccount(email: 'not-an-email').maskedEmail, 'not-an-email');
    });
  });

  group('consultationMinutes', () {
    test('uses the doctor-configured value when present', () {
      expect(buildAccount(avgConsultationMinutes: 15).consultationMinutes, 15);
    });

    test('falls back to 5 minutes for doctors registered before the field', () {
      expect(buildAccount().consultationMinutes, 5);
    });
  });

  group('clinic hours', () {
    test('defaults to the 08:00-14:00 window', () {
      final AuthAccount account = buildAccount();
      expect(account.clinicStartTimeOrDefault, '08:00');
      expect(account.clinicEndTimeOrDefault, '14:00');
    });

    test('honours times the doctor has set', () {
      final AuthAccount account = buildAccount(
        clinicStartTime: '10:30',
        clinicEndTime: '18:00',
      );
      expect(account.clinicStartTimeOrDefault, '10:30');
      expect(account.clinicEndTimeOrDefault, '18:00');
    });
  });

  group('copyWith', () {
    test('overrides only the named fields', () {
      final AuthAccount updated = buildAccount().copyWith(firstName: 'Nabil');
      expect(updated.firstName, 'Nabil');
      expect(updated.lastName, 'Rahman');
      expect(updated.userId, '4821');
      expect(updated.role, AuthRole.patient);
    });

    test('leaves the original untouched', () {
      final AuthAccount original = buildAccount();
      original.copyWith(firstName: 'Nabil');
      expect(original.firstName, 'Tareq');
    });
  });

  group('AuthRoleX labels', () {
    test('every role has a label, short label and icon', () {
      for (final AuthRole role in AuthRole.values) {
        expect(role.label, isNotEmpty);
        expect(role.shortLabel, isNotEmpty);
        expect(role.icon, isNotNull);
      }
    });

    test('shortens only the lab specialist label', () {
      expect(AuthRole.labSpecialist.label, 'Lab Specialist');
      expect(AuthRole.labSpecialist.shortLabel, 'Lab');
      expect(AuthRole.doctor.label, AuthRole.doctor.shortLabel);
    });
  });
}
