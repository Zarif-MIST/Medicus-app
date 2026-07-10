import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../Models/auth_account.dart';
import 'package:medicus/Features/Authentication/Models/auth_role.dart';
import '../../Screens/email_verification/email_verification_screen.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/sizes.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  const RegistrationSuccessScreen({super.key, required this.account});

  final AuthAccount account;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFFDF2F0), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Sizes.responsivePadding(context)),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 460),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF181818) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: MColors.primaryColor.withValues(alpha: 0.12)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 28,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/Images/OnBoard/Doctors-bro.svg',
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 14),
                    const Icon(Icons.verified_rounded, color: MColors.primaryColor, size: 56),
                    const SizedBox(height: 14),
                    Text(
                      'Registration successful',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your 4-digit user ID and verification details are ready for ${account.maskedEmail}.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    _InfoChip(label: 'Role', value: account.role.label),
                    const SizedBox(height: 10),
                    _InfoChip(label: 'User ID', value: account.userId),
                    const SizedBox(height: 10),
                    _InfoChip(label: 'Verification email', value: account.email),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.to(
                            () => EmailVerificationScreen(account: account),
                            transition: Transition.rightToLeft,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Verify Email Code'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Back to registration'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
