import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({this.authService, super.key});

  final AuthService? authService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late final AuthService _authService = widget.authService ?? AuthService();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await _authService.register(fullName: _nameController.text, email: _emailController.text, password: _passwordController.text);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => EmailVerificationScreen(authService: _authService)), (route) => false);
      }
    } catch (error) {
      if (mounted) _showMessage(authErrorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: isError ? Colors.red.shade700 : primaryGreen));

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [IconButton(onPressed: _busy ? null : () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back)), const Spacer(), const BrandMark(), const Spacer(), const SizedBox(width: 48)]),
          const SizedBox(height: 16),
          Text('Create your account', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Text('Join MindCare Wellness for confidential support', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
          const SizedBox(height: 28),
          AuthTextField(controller: _nameController, label: 'Full name', hint: 'e.g. Kausar Perera', icon: Icons.person_outline_rounded, validator: (value) => requiredValue(value, 'Full name is required')),
          const SizedBox(height: 15),
          AuthTextField(controller: _emailController, label: 'Email address', hint: 'you@example.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress, validator: emailValue),
          const SizedBox(height: 15),
          AuthTextField(controller: _passwordController, label: 'Password', hint: 'At least 8 characters', icon: Icons.lock_outline_rounded, obscureText: _obscurePassword, onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword), validator: passwordValue),
          const SizedBox(height: 15),
          AuthTextField(controller: _confirmController, label: 'Confirm password', hint: 'Re-enter your password', icon: Icons.lock_reset_outlined, obscureText: _obscureConfirm, onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm), validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null),
          const SizedBox(height: 18),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: mintGreen.withValues(alpha: .55), borderRadius: BorderRadius.circular(14)), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.verified_user_outlined, color: primaryGreen, size: 20), SizedBox(width: 10), Expanded(child: Text('Your information stays private and secure. We will send a verification email after sign up.', style: TextStyle(fontSize: 12, height: 1.4)))])),
          const SizedBox(height: 20),
          PrimaryButton(label: 'CREATE ACCOUNT  →', onPressed: _register, busy: _busy),
          const SizedBox(height: 18),
          Center(child: Text.rich(TextSpan(text: 'Already have an account? ', children: [WidgetSpan(child: GestureDetector(onTap: _busy ? null : () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('Log in', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700))))]))),
        ]),
      ),
    );
  }
}
