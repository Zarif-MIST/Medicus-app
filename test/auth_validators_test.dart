import 'package:flutter_test/flutter_test.dart';
import 'package:medicus/Utilities/auth_validators.dart';

void main() {
  group('requiredField', () {
    test('rejects null, empty and whitespace-only values', () {
      for (final String? value in <String?>[null, '', '   ', '\t\n']) {
        expect(AuthValidators.requiredField(value), 'This field is required');
      }
    });

    test('accepts any non-blank value', () {
      expect(AuthValidators.requiredField('a'), isNull);
    });
  });

  group('email', () {
    test('accepts ordinary addresses', () {
      for (final String value in <String>[
        'tareq@example.com',
        'a.b+tag@sub.domain.co.uk',
        '  spaced@example.com  ',
      ]) {
        expect(AuthValidators.email(value), isNull, reason: value);
      }
    });

    test('rejects malformed addresses', () {
      for (final String value in <String>[
        'no-at-sign',
        'no@domain',
        'two@@example.com',
        'spa ce@example.com',
        '@example.com',
      ]) {
        expect(
          AuthValidators.email(value),
          'Enter a valid email address',
          reason: value,
        );
      }
    });
  });

  group('userId', () {
    test('accepts exactly four digits', () {
      expect(AuthValidators.userId('4821'), isNull);
      expect(AuthValidators.userId(' 4821 '), isNull);
    });

    test('rejects anything that is not four digits', () {
      for (final String value in <String>['482', '48210', '48a1', 'abcd']) {
        expect(
          AuthValidators.userId(value),
          'Enter the 4-digit user ID',
          reason: value,
        );
      }
    });
  });

  group('password', () {
    test('accepts a password meeting every rule', () {
      expect(AuthValidators.password('Str0ng!pass'), isNull);
    });

    test('names each missing requirement', () {
      final String? result = AuthValidators.password('abc');
      expect(result, contains('8+ characters'));
      expect(result, contains('one uppercase letter'));
      expect(result, contains('one number'));
      expect(result, contains('one special character'));
      // 'abc' does have a lowercase letter, so that rule must not be listed.
      expect(result, isNot(contains('one lowercase letter')));
    });

    test('reports only the single rule that fails', () {
      expect(
        AuthValidators.password('Str0ngpass'),
        'Use a stronger password with one special character',
      );
    });
  });

  group('confirmPassword', () {
    test('accepts a matching pair, ignoring surrounding whitespace', () {
      expect(AuthValidators.confirmPassword(' Str0ng!pass ', 'Str0ng!pass'),
          isNull);
    });

    test('rejects a mismatch', () {
      expect(
        AuthValidators.confirmPassword('Str0ng!pass', 'Different1!'),
        'Passwords do not match',
      );
    });
  });

  group('bangladeshPhone', () {
    test('accepts valid operator prefixes and common formatting', () {
      for (final String value in <String>[
        '01712345678',
        '01912345678',
        '017-1234-5678',
        '017 1234 5678',
      ]) {
        expect(AuthValidators.bangladeshPhone(value), isNull, reason: value);
      }
    });

    test('rejects bad prefixes and wrong lengths', () {
      for (final String value in <String>[
        '01212345678',
        '0171234567',
        '017123456789',
        '11712345678',
      ]) {
        expect(
          AuthValidators.bangladeshPhone(value),
          'Enter a valid number after +88',
          reason: value,
        );
      }
    });
  });

  group('numericCode', () {
    test('defaults to six digits', () {
      expect(AuthValidators.numericCode('123456'), isNull);
      expect(AuthValidators.numericCode('12345'), 'Enter the 6 digit code');
    });

    test('honours a custom length', () {
      expect(AuthValidators.numericCode('1234', length: 4), isNull);
      expect(
        AuthValidators.numericCode('123456', length: 4),
        'Enter the 4 digit code',
      );
    });

    test('rejects non-digits of the right length', () {
      expect(AuthValidators.numericCode('12a456'), 'Enter the 6 digit code');
    });
  });

  group('consultationMinutes', () {
    test('treats an empty value as valid, since callers have a default', () {
      expect(AuthValidators.consultationMinutes(null), isNull);
      expect(AuthValidators.consultationMinutes('  '), isNull);
    });

    test('accepts the inclusive 1-120 range', () {
      expect(AuthValidators.consultationMinutes('1'), isNull);
      expect(AuthValidators.consultationMinutes('120'), isNull);
    });

    test('rejects values outside the range or not a number', () {
      for (final String value in <String>['0', '121', 'ten', '-5', '1.5']) {
        expect(
          AuthValidators.consultationMinutes(value),
          'Enter minutes between 1 and 120',
          reason: value,
        );
      }
    });
  });

  group('nid', () {
    test('accepts 10 to 17 digits and ignores spacing', () {
      expect(AuthValidators.nid('1234567890'), isNull);
      expect(AuthValidators.nid('12345678901234567'), isNull);
      expect(AuthValidators.nid('1234 5678 90'), isNull);
    });

    test('rejects too short, too long, or non-numeric values', () {
      for (final String value in <String>[
        '123456789',
        '123456789012345678',
        '12345678ab',
      ]) {
        expect(
          AuthValidators.nid(value),
          'Enter a valid NID or birth certificate number',
          reason: value,
        );
      }
    });
  });
}
