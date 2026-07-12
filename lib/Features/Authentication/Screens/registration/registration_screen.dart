import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Authentication/Models/auth_role.dart';
import 'package:medicus/Features/Authentication/Services/auth_registry.dart';
import 'package:medicus/Features/Authentication/Widgets/auth_role_selector.dart';
import 'package:medicus/Features/Authentication/Widgets/auth_text_field.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/auth_validators.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({
    super.key,
    this.selectedRole,
  });

  final AuthRole? selectedRole;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _pharmacyNameController = TextEditingController();
  final TextEditingController _tradeLicenseController = TextEditingController();
  final TextEditingController _nidController = TextEditingController();

  AuthRole? _selectedRole;
  String? _selectedSpecialty;
  bool _showVerificationStep = false;
  bool _verificationCompleted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  AuthAccount? _registeredAccount;
  final TextEditingController _verificationCodeController = TextEditingController();

  static const List<String> _doctorSpecialties = <String>[
    'Dentist',
    'Surgeon',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'General Physician',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.selectedRole;
  }

  @override
  void didUpdateWidget(covariant RegistrationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRole != oldWidget.selectedRole && _registeredAccount == null) {
      _selectedRole = widget.selectedRole;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseController.dispose();
    _pharmacyNameController.dispose();
    _tradeLicenseController.dispose();
    _nidController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = MHelperFunctions.isDarkMode(context);

    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF181818) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: MColors.primaryColor.withValues(alpha: 0.10)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: _verificationCompleted
              ? _buildCompletedView(context, dark, _registeredAccount!)
              : _showVerificationStep && _registeredAccount != null
                  ? _buildVerificationView(context, dark, _registeredAccount!)
                  : _registeredAccount != null
                      ? _buildSuccessView(context, dark, _registeredAccount!)
                      : _buildForm(context, dark),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool dark) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('registration-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create account',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick a role and complete the matching fields.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Text(
            'Choose your role',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          AuthRoleSelector(
            selectedRole: _selectedRole,
            dark: dark,
            onChanged: (AuthRole role) {
              setState(() {
                _selectedRole = role;
                _selectedSpecialty = null;
              });
            },
          ),
          const SizedBox(height: 18),
          if (_selectedRole != null) ...[
            if (_selectedRole == AuthRole.doctor) ...[
              AuthTextField(
                controller: _firstNameController,
                label: 'First name',
                validator: AuthValidators.requiredField,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _lastNameController,
                label: 'Last name',
                validator: AuthValidators.requiredField,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedSpecialty,
                items: _doctorSpecialties
                    .map(
                      (String specialty) => DropdownMenuItem<String>(
                        value: specialty,
                        child: Text(specialty),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) => setState(() => _selectedSpecialty = value),
                validator: (String? value) => value == null ? 'Select your specialty' : null,
                decoration: _fieldDecoration('Area of specialty'),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _licenseController,
                label: 'BMDC license number',
                validator: AuthValidators.requiredField,
              ),
            ] else if (_selectedRole == AuthRole.pharmacist) ...[
              AuthTextField(
                controller: _firstNameController,
                label: 'First name',
                validator: AuthValidators.requiredField,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _lastNameController,
                label: 'Last name',
                validator: AuthValidators.requiredField,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _pharmacyNameController,
                label: 'Pharmacy name',
                validator: AuthValidators.requiredField,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _tradeLicenseController,
                label: 'Trade license number',
                validator: AuthValidators.requiredField,
              ),
            ] else if (_selectedRole == AuthRole.patient) ...[
              AuthTextField(
                controller: _firstNameController,
                label: 'First name',
                validator: AuthValidators.requiredField,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _lastNameController,
                label: 'Last name',
                validator: AuthValidators.requiredField,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _nidController,
                label: 'NID or birth certificate number',
                keyboardType: TextInputType.number,
                validator: AuthValidators.nid,
              ),
            ] else if (_selectedRole == AuthRole.labSpecialist) ...[
              AuthTextField(
                controller: _firstNameController,
                label: 'First name',
                validator: AuthValidators.requiredField,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _lastNameController,
                label: 'Last name',
                validator: AuthValidators.requiredField,
              ),
            ],
            const SizedBox(height: 12),
            AuthTextField(
              controller: _emailController,
              label: 'Email address',
              keyboardType: TextInputType.emailAddress,
              validator: AuthValidators.email,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _phoneController,
              label: 'Phone number',
              prefixText: '+88 ',
              keyboardType: TextInputType.phone,
              maxLength: 11,
              helperText: 'Enter the 11 digits after the Bangladeshi country code.',
              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
              validator: AuthValidators.bangladeshPhone,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _passwordController,
              label: 'Password',
              obscureText: _obscurePassword,
              validator: AuthValidators.password,
              helperText: 'Use 8+ characters with upper, lower, number, and symbol.',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              ),
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _confirmPasswordController,
              label: 'Confirm password',
              obscureText: _obscureConfirmPassword,
              validator: (String? value) => AuthValidators.confirmPassword(
                value,
                _passwordController.text,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
                tooltip: _obscureConfirmPassword ? 'Show password' : 'Hide password',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Register'),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Swipe the sheet down when you are done to return to login.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MColors.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Choose a role first to unlock the matching registration fields.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, bool dark, AuthAccount account) {
    return Column(
      key: const ValueKey('registration-success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Registration successful',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : Colors.black87,
              ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: MColors.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.verified_rounded, color: MColors.primaryColor, size: 54),
              const SizedBox(height: 12),
              Text(
                'User ID: ${account.userId}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'A verification email was sent to ${account.maskedEmail}.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: 280,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showVerificationStep = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Continue To Email Verification'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Swipe the sheet down to return to login after you are finished.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildVerificationView(BuildContext context, bool dark, AuthAccount account) {
    return Column(
      key: const ValueKey('registration-verification'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Email verification',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : Colors.black87,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the verification code sent to ${account.maskedEmail}.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        AuthTextField(
          controller: _verificationCodeController,
          label: 'Verification code',
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
          validator: (String? value) => AuthValidators.numericCode(value, length: 4),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _verifyEmail(account),
            style: ElevatedButton.styleFrom(
              backgroundColor: MColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Complete Verification'),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedView(BuildContext context, bool dark, AuthAccount account) {
    return Column(
      key: const ValueKey('registration-complete'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'All done',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : Colors.black87,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MColors.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.verified_user, color: MColors.primaryColor, size: 48),
              const SizedBox(height: 10),
              Text('User ID: ${account.userId}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Email verified. Swipe the sheet down and login with your role.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: MColors.primaryColor),
      ),
    );
  }

  Future<void> _register() async {
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _selectedRole == null) {
      if (_selectedRole == null) {
        Get.snackbar(
          'Select a role',
          'Choose a role before registering.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return;
    }

    if (_selectedRole == AuthRole.doctor && _selectedSpecialty == null) {
      Get.snackbar(
        'Missing specialty',
        'Select an area of specialty for the doctor account.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final AuthAccount account = AuthAccount(
      userId: '',
      role: _selectedRole!,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phoneNumber: '+88${_phoneController.text.trim()}',
      verificationCode: '',
      specialty: _selectedSpecialty,
      licenseNumber: _licenseController.text.trim(),
      pharmacyName: _pharmacyNameController.text.trim(),
      tradeLicense: _tradeLicenseController.text.trim(),
      nidNumber: _nidController.text.trim(),
    );

    try {
      final AuthAccount registeredAccount = await AuthRegistry.instance.register(account);
      if (!mounted) {
        return;
      }
      setState(() {
        _registeredAccount = registeredAccount;
        _showVerificationStep = false;
        _verificationCompleted = false;
      });
      Get.snackbar(
        'Verification email sent',
        'A verification code was sent to ${registeredAccount.maskedEmail}.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (error) {
      Get.snackbar(
        'Registration failed',
        error.message ?? 'Could not create the account. Try a different email.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Registration failed',
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _verifyEmail(AuthAccount account) async {
    final String? codeValidation = AuthValidators.numericCode(
      _verificationCodeController.text,
      length: 4,
    );

    if (codeValidation != null) {
      Get.snackbar(
        'Invalid code',
        codeValidation,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final bool verified = await AuthRegistry.instance.verifyEmail(
      userId: account.userId,
      code: _verificationCodeController.text,
    );

    if (!verified) {
      Get.snackbar(
        'Verification failed',
        'The code does not match the one sent to ${account.maskedEmail}.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _verificationCompleted = true;
      _showVerificationStep = false;
    });
  }
}
