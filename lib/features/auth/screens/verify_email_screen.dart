/// Verify Email Screen
/// Prompts user to verify their email address after registration
library;

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/constants/theme.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isResending = false;
  bool _isChecking = false;
  bool _resentSuccess = false;

  String get _userEmail =>
      FirebaseAuth.instance.currentUser?.email ?? 'your email';

  Future<void> _resendVerification() async {
    setState(() {
      _isResending = true;
      _resentSuccess = false;
    });
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        setState(() {
          _isResending = false;
          _resentSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _checkVerified() async {
    setState(() => _isChecking = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        setState(() => _isChecking = false);
        if (user != null && user.emailVerified) {
          context.go(AppRoutes.connectWallet);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Email not yet verified. Please check your inbox.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 56,
                    color: AppTheme.infoColor,
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Verify Your Email',
                  style: AppTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a verification link to:\n$_userEmail',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please click the link in the email to activate your account.',
                  style: AppTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Resent confirmation
                if (_resentSuccess)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.successColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppTheme.successColor, size: 18),
                        const SizedBox(width: 8),
                        const Text('Verification email resent!',
                            style: TextStyle(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),

                // Check verified
                ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkVerified,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                      : const Icon(Icons.verified_user_outlined),
                  label: const Text("I've Verified My Email"),
                ),
                const SizedBox(height: 12),

                // Resend
                OutlinedButton.icon(
                  onPressed: _isResending ? null : _resendVerification,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _isResending
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Resend Verification Email'),
                ),
                const SizedBox(height: 24),

                // Steps
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What to do:',
                        style: AppTheme.titleSmall
                            .copyWith(color: AppTheme.textSecondaryColor),
                      ),
                      const SizedBox(height: 10),
                      _step('1', 'Open the email we sent you'),
                      _step('2', 'Click the "Verify Email" button'),
                      _step('3', 'Return here and tap "I\'ve Verified"'),
                      _step('4', 'Check your spam folder if not found'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                TextButton(
                  onPressed: _signOut,
                  child: Text(
                    'Sign out and use a different account',
                    style: AppTheme.labelMedium
                        .copyWith(color: AppTheme.textSecondaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
