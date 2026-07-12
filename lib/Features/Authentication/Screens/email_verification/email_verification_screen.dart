import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../Models/auth_account.dart';
import '../../Services/auth_registry.dart';
import 'package:medicus/Utilities/auth_validators.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/sizes.dart';
import '../login/login.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, required this.account});

  final AuthAccount account;

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/Images/OnBoard/Hospital patient-rafiki.svg',
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Verify your email',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'A verification code has been sent to ${widget.account.maskedEmail}. Use it below to activate the account.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: MColors.primaryColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('User ID', style: Theme.of(context).textTheme.bodyMedium),
                            Text(
                              widget.account.userId,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                        validator: (String? value) => AuthValidators.numericCode(value, length: 4),
                        decoration: InputDecoration(
                          labelText: '4-digit verification code',
                          counterText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: MColors.primaryColor),
                          ),
                          helperText: 'Use the latest code sent to your email inbox.',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () async {
                          await AuthRegistry.instance.updateVerificationCode(userId: widget.account.userId);
                          Get.snackbar(
                            'Verification code refreshed',
                            'A new code is ready for ${widget.account.maskedEmail}.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        child: const Text('Resend code'),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _verify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Confirm verification'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verify() async {
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final bool verified = await AuthRegistry.instance.verifyEmail(
      userId: widget.account.userId,
      code: _codeController.text,
    );

    if (!verified) {
      Get.snackbar(
        'Verification failed',
        'The code does not match the one sent to ${widget.account.maskedEmail}.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.offAll(
      () => LoginScreen(
        initialUserId: widget.account.userId,
        initialRole: widget.account.role,
      ),
      transition: Transition.fadeIn,
    );
  }
}
