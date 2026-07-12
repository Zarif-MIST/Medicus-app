import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:medicus/Features/Authentication/Models/auth_role.dart';
import '../../Models/auth_account.dart';
import '../registration/registration_screen.dart';
import '../email_verification/email_verification_screen.dart';
import '../../Services/auth_registry.dart';
import 'package:medicus/Utilities/auth_validators.dart';
import '../../Widgets/auth_role_selector.dart';
import '../../Widgets/auth_text_field.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/doctor_dash.dart';
import 'package:medicus/Features/Role_Based_Interface/Lab_Specialist/Screens/lab_dash.dart';
import 'package:medicus/Features/Role_Based_Interface/Pharmacist/Screens/pharm_dash.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/pat_dash.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialUserId, this.initialRole});

  final String? initialUserId;
  final AuthRole? initialRole;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  AuthRole? _selectedRole;
  bool _isRegisterSheetExpanded = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _userIdController.text = widget.initialUserId ?? '';
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = MHelperFunctions.isDarkMode(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF181818) : Colors.white,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: Sizes.responsiveHeight(context, 0.12, min: 90, max: 140),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 460),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF181818) : Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Image.asset(
                            dark ? 'assets/Logos/M_dark1152.png' : 'assets/Logos/M1152.png',
                            height: Sizes.responsiveHeight(context, 0.15, min: 88, max: 140),
                          ),
                          SizedBox(height: Sizes.responsiveHeight(context, 0.02, min: 12, max: 18)),
                          Text(
                            'Welcome back',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          SizedBox(height: Sizes.responsiveHeight(context, 0.015, min: 8, max: 14)),
                          Text(
                            'Login with your 4-digit user ID, password, and role.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: Sizes.responsiveHeight(context, 0.02, min: 12, max: 18)),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AuthTextField(
                                  controller: _userIdController,
                                  label: 'User ID',
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  validator: AuthValidators.userId,
                                ),
                                const SizedBox(height: 14),
                                AuthTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  obscureText: _obscurePassword,
                                  validator: AuthValidators.requiredField,
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
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: MColors.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: const Text('Login'),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _buildRoleHeader(context, dark),
                                const SizedBox(height: 12),
                                AuthRoleSelector(
                                  selectedRole: _selectedRole,
                                  dark: dark,
                                  onChanged: (AuthRole role) => setState(() => _selectedRole = role),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              NotificationListener<DraggableScrollableNotification>(
                onNotification: (DraggableScrollableNotification notification) {
                  final bool expanded = notification.extent > 0.2;
                  if (expanded != _isRegisterSheetExpanded) {
                    setState(() {
                      _isRegisterSheetExpanded = expanded;
                    });
                  }
                  return false;
                },
                child: DraggableScrollableSheet(
                  initialChildSize: 0.14,
                  minChildSize: 0.08,
                  maxChildSize: 0.9,
                  snap: true,
                  snapSizes: const [0.14, 0.9],
                  builder: (BuildContext context, ScrollController scrollController) {
                    return Container(
                      margin: const EdgeInsets.only(top: 24),
                      clipBehavior: Clip.hardEdge,
                      decoration:  BoxDecoration(
                        color: MColors.primaryColor,
                        border: Border.all(
                          color: MColors.primaryColor.withValues(alpha: 0.10),
                          width: 10,
                          style: BorderStyle.solid
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(36),
                          topRight: Radius.circular(36),
                        ),
                        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.only(
                          left: Sizes.responsivePadding(context),
                          right: Sizes.responsivePadding(context),
                          top: 12,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                        ),
                        children: [
                          Center(
                            child: Container(
                              width: 48,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.white70,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isRegisterSheetExpanded ? 'Swipe down to login' : 'Swipe up to register',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Sizes.responsiveFontSize(context, 18, min: 16, max: 20),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 48),
                          Text(
                            _isRegisterSheetExpanded
                                ? 'Finish the registration here'
                                : 'Open the sheet to complete registration.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 48),
                          RegistrationScreen(
                            selectedRole: _selectedRole,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleHeader(BuildContext context, bool dark) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: dark ? Colors.white70 : Colors.grey,
            thickness: 0.5,
            endIndent: 8,
          ),
        ),
        Text(
          'Choose Your Role',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Expanded(
          child: Divider(
            color: dark ? Colors.white70 : Colors.grey,
            thickness: 0.5,
            indent: 8,
          ),
        ),
      ],
    );
  }

  Future<void> _login() async {
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final AuthRole? role = _selectedRole;
    if (role == null) {
      Get.snackbar(
        'Select a role',
        'Choose the account role before logging in.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final AuthAccount? account = await AuthRegistry.instance.login(
      userId: _userIdController.text,
      password: _passwordController.text,
      role: role,
    );

    if (account == null) {
      Get.snackbar(
        'Login failed',
        'Check the user ID, password, and selected role.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!account.isVerified) {
      Get.to(
        () => EmailVerificationScreen(account: account),
        transition: Transition.fadeIn,
      );
      return;
    }

    if (account.role == AuthRole.doctor) {
      Get.offAll(
        () => DoctorDash(),
        transition: Transition.fadeIn,
      );
    } else if (account.role == AuthRole.labSpecialist) {
      Get.offAll(
        () => LabDashboardScreen(),
        transition: Transition.fadeIn,
      );
    } else if (account.role == AuthRole.pharmacist) {
      Get.offAll(
        () => PharmacistDashboardScreen(),
        transition: Transition.fadeIn,
      );
    } else if (account.role == AuthRole.patient) {
      Get.offAll(
        () => PatientDashboardScreen(),
        transition: Transition.fadeIn,
      );
    }
  }
}
