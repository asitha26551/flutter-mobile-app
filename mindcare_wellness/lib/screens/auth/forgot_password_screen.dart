import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AuthService().resetPassword(_emailController.text);
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authErrorMessage(error)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          const BrandMark(),
          const SizedBox(height: 20),
          Text(
            _sent ? 'Check your inbox' : 'Reset your password',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          Text(
            _sent
                ? 'We sent password reset instructions to ${_emailController.text.trim()}.'
                : 'Enter your account email and we will send you a secure reset link.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 28),
          if (!_sent)
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email address',
                    hint: 'you@example.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: emailValue,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'SEND RESET LINK',
                    onPressed: _sendResetEmail,
                    busy: _busy,
                  ),
                ],
              ),
            )
          else ...[
            const Icon(
              Icons.mark_email_read_outlined,
              size: 64,
              color: primaryGreen,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => setState(() => _sent = false),
              child: const Text('Use another email'),
            ),
          ],
        ],
      ),
    );
  }
}
