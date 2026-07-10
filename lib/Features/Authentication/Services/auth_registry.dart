import 'dart:math';

import '../Models/auth_account.dart';
import '../Models/auth_role.dart';

class AuthRegistry {
  AuthRegistry._();

  static final AuthRegistry instance = AuthRegistry._();

  final Map<String, AuthAccount> _accounts = <String, AuthAccount>{};

  static final Random _random = Random.secure();

  AuthAccount register(AuthAccount account) {
    final String userId = account.userId.isEmpty ? _generateUniqueUserId() : account.userId;
    final String verificationCode = account.verificationCode.isEmpty
        ? _generateVerificationCode()
        : account.verificationCode;

    final AuthAccount stored = account.copyWith(
      userId: userId,
      verificationCode: verificationCode,
      isVerified: false,
    );
    _accounts[userId] = stored;
    return stored;
  }

  AuthAccount? accountForUserId(String userId) {
    return _accounts[userId.trim()];
  }

  AuthAccount? login({
    required String userId,
    required String password,
    required AuthRole role,
  }) {
    final AuthAccount? account = accountForUserId(userId);
    if (account == null) {
      return null;
    }

    if (!account.isVerified) {
      return null;
    }

    if (account.password != password) {
      return null;
    }

    if (account.role != role) {
      return null;
    }

    return account;
  }

  bool verifyEmail({
    required String userId,
    required String code,
  }) {
    final AuthAccount? account = accountForUserId(userId);
    if (account == null || account.verificationCode != code.trim()) {
      return false;
    }

    _accounts[userId] = account.copyWith(isVerified: true);
    return true;
  }

  void updateVerificationCode({
    required String userId,
  }) {
    final AuthAccount? account = accountForUserId(userId);
    if (account == null) {
      return;
    }

    _accounts[userId] = account.copyWith(verificationCode: _generateVerificationCode());
  }

  String _generateUniqueUserId() {
    for (int attempt = 0; attempt < 1000; attempt++) {
      final String userId = (1000 + _random.nextInt(9000)).toString();
      if (!_accounts.containsKey(userId)) {
        return userId;
      }
    }

    throw StateError('Unable to generate a unique 4-digit user ID.');
  }

  String _generateVerificationCode() {
    return '1234';
  }
}
