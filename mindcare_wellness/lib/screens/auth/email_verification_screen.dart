import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/auth_gate.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({required this.authService, super.key});

  final AuthService authService;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _busy = false;
  String? _message;

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final verified = await widget.authService.isEmailVerified();
      if (!mounted) return;
      if (verified) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => AuthGate(authService: widget.authService),
          ),
          (route) => false,
        );
      } else {
        setState(
          () => _message =
              'Not verified yet. Open the email link, then try again.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _message = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      await widget.authService.sendVerificationEmail();
      if (mounted)
        setState(() => _message = 'A new verification email has been sent.');
    } catch (error) {
      if (mounted) setState(() => _message = authErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BrandMark(),
          const SizedBox(height: 24),
          Text(
            'Verify your email',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          const Text(
            'We sent a verification link to your email address. Verify it to keep your MindCare account protected.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.45),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              color: primaryGreen,
              size: 58,
            ),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: "I'VE VERIFIED MY EMAIL",
            onPressed: _refresh,
            busy: _busy,
          ),
          TextButton(
            onPressed: _busy ? null : _resend,
            child: const Text('Resend verification email'),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: primaryGreen),
              ),
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _busy ? null : () => widget.authService.logout(),
            child: const Text('Use a different account'),
          ),
        ],
      ),
    );
  }
}
