import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Models/auth_account.dart';
import '../Models/auth_role.dart';

class AuthRegistry {
  AuthRegistry._();

  static final AuthRegistry instance = AuthRegistry._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final Random _random = Random.secure();

  Future<AuthAccount> register(AuthAccount account) async {
    final String userId = await _generateUniqueUserId();
    final String verificationCode = _generateVerificationCode();

    final UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: account.email,
      password: account.password,
    );

    final AuthAccount stored = account.copyWith(
      userId: userId,
      verificationCode: verificationCode,
      isVerified: false,
    );

    final Map<String, dynamic> payload = _toFirestoreMap(
      stored,
      firebaseUid: credential.user!.uid,
    );

    await _firestore.collection('users').doc(credential.user!.uid).set(payload);
    
    await _queueVerificationEmail(stored);
    await _auth.signOut();

    return stored;
  }

  Future<AuthAccount?> accountForUserId(String userId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('users')
        .where('userId', isEqualTo: userId.trim())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return _fromFirestore(snapshot.docs.first.id, snapshot.docs.first.data());
  }

  Future<AuthAccount?> login({
    required String userId,
    required String password,
    required AuthRole role,
  }) async {
    final AuthAccount? account = await accountForUserId(userId);
    if (account == null) {
      return null;
    }

    if (account.role != role) {
      return null;
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: account.email,
        password: password,
      );
    } on FirebaseAuthException {
      return null;
    }

    if (!account.isVerified) {
      // Allow credentials check, but keep unverified users signed out until they verify.
      await _auth.signOut();
    }

    return account;
  }

  Future<bool> verifyEmail({
    required String userId,
    required String code,
  }) async {
    final AuthAccount? account = await accountForUserId(userId);
    if (account == null || account.verificationCode != code.trim()) {
      return false;
    }

    await _firestore.collection('users').doc(account.firebaseUid).update(<String, dynamic>{
      'isVerified': true,
    });
    return true;
  }

  Future<void> updateVerificationCode({
    required String userId,
  }) async {
    final AuthAccount? account = await accountForUserId(userId);
    if (account == null) {
      return;
    }

    final String newCode = _generateVerificationCode();

    await _firestore.collection('users').doc(account.firebaseUid).update(<String, dynamic>{
      'verificationCode': newCode,
    });

    await _queueVerificationEmail(
      account.copyWith(verificationCode: newCode),
    );
  }

  Future<String> _generateUniqueUserId() async {
    for (int attempt = 0; attempt < 1000; attempt++) {
      final String userId = (1000 + _random.nextInt(9000)).toString();

      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return userId;
      }
    }

    throw StateError('Unable to generate a unique 4-digit user ID.');
  }

  String _generateVerificationCode() {
    return (1000 + _random.nextInt(9000)).toString();
  }

Future<void> _queueVerificationEmail(AuthAccount account) async {
  final String mailerSendApiKey = 'mlsn.5656c50b5c64daf8fd5607bceb60aa4c745c804f3407df1ea21a205503e54822';
  final String fromEmail = 'your@test-3m5jgrop7yogdpyo.mlsender.net';
  const String fromName = 'Medicus';

  if (mailerSendApiKey.isEmpty || fromEmail.isEmpty) {
    throw StateError('Missing MAILERSEND_API_KEY or MAILERSEND_FROM_EMAIL dart-define values.');
  }

  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $mailerSendApiKey',
  };

  final Map<String, dynamic> body = {
    'from': {
      'email': fromEmail,
      'name': fromName,
    },
    'to': [
      {'email': account.email}
    ],
    'subject': 'Your Medicus verification code',
    'html': '''
      <p>Welcome to <strong>Medicus</strong>!</p>
      <p><strong>User ID:</strong> ${account.userId}<br/>
      <strong>Verification code:</strong> ${account.verificationCode}</p>
      <p>Enter this code in the app to verify your account.</p>
    ''',
    'text': 'Welcome to Medicus!\n\nUser ID: ${account.userId}\nVerification code: ${account.verificationCode}\n\nEnter this code in the app to verify your account.',
  };

  final response = await http.post(
    Uri.parse('https://api.mailersend.com/v1/email'),
    headers: headers,
    body: jsonEncode(body),
  );

  if (response.statusCode != 202) {
    throw StateError('MailerSend rejected email with status ${response.statusCode}: ${response.body}');
  }
}

  Map<String, dynamic> _toFirestoreMap(AuthAccount account, {required String firebaseUid}) {
    return <String, dynamic>{
      'firebaseUid': firebaseUid,
      'userId': account.userId,
      'role': account.role.name,
      'firstName': account.firstName,
      'lastName': account.lastName,
      'email': account.email,
      'phoneNumber': account.phoneNumber,
      'verificationCode': account.verificationCode,
      'specialty': account.specialty,
      'gender': account.gender,
      'licenseNumber': account.licenseNumber,
      'pharmacyName': account.pharmacyName,
      'tradeLicense': account.tradeLicense,
      'nidNumber': account.nidNumber,
      'pharmacyLocation': account.pharmacyLocation,
      'isVerified': account.isVerified,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  AuthAccount _fromFirestore(String firebaseUid, Map<String, dynamic> data) {
    return AuthAccount(
      firebaseUid: firebaseUid,
      userId: (data['userId'] ?? '') as String,
      role: _roleFromString((data['role'] ?? 'patient') as String),
      firstName: (data['firstName'] ?? '') as String,
      lastName: (data['lastName'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      password: '',
      phoneNumber: (data['phoneNumber'] ?? '') as String,
      verificationCode: (data['verificationCode'] ?? '') as String,
      specialty: data['specialty'] as String?,
      gender: data['gender'] as String?,
      licenseNumber: data['licenseNumber'] as String?,
      pharmacyName: data['pharmacyName'] as String?,
      tradeLicense: data['tradeLicense'] as String?,
      nidNumber: data['nidNumber'] as String?,
      pharmacyLocation: data['pharmacyLocation'] as String?,
      isVerified: (data['isVerified'] ?? false) as bool,
    );
  }

  AuthRole _roleFromString(String value) {
    switch (value) {
      case 'doctor':
        return AuthRole.doctor;
      case 'pharmacist':
        return AuthRole.pharmacist;
      case 'labSpecialist':
        return AuthRole.labSpecialist;
      case 'patient':
      default:
        return AuthRole.patient;
    }
  }
}
