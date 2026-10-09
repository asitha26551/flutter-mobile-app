import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/auth_service.dart';
import '../../services/student_profile_service.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/common/error_message.dart';
import '../../widgets/common/loading.dart';
import 'emergency_support_screen.dart';
import 'notifications_screen.dart';
import 'reminder_preferences_screen.dart';

/// Settings hub (FR-04 area): profile (read + update), shortcuts to
/// reminders, notifications and emergency support, and log out.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.authService,
    this.profileService,
    super.key,
  });

  final AuthService authService;
  final StudentProfileService? profileService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final StudentProfileService _service =
      widget.profileService ?? StudentProfileService();
  late final Stream<Map<String, dynamic>> _profile = _service.watch();

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  Future<void> _callHotline() async {
    const number = EmergencyNumbers.crisisHotline;
    try {
      final launched = await launchUrl(Uri(scheme: 'tel', path: number));
      if (!launched) _snack('Could not open the phone app. Please dial $number.');
    } catch (_) {
      _snack('Could not open the phone app. Please dial $number.');
    }
  }

  Future<void> _editProfile(Map<String, dynamic> data) async {
    final message = await showDialog<String>(
      context: context,
      builder: (_) => _ProfileDialog(service: _service, data: data),
    );
    if (message != null) _snack(message);
  }

  Future<void> _logout() async {
    await widget.authService.logout();
    // Settings was pushed on top of the home screen, so close it as well.
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _profile,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const ErrorMessage(
              message: 'We could not load your profile. Please try again.',
            );
          }
          if (!snapshot.hasData) return const LoadingWidget();
          final data = snapshot.data!;
          final name = (data['fullName'] as String?) ?? '';
          final email = (data['email'] as String?) ?? '';
          final phone = (data['phoneNumber'] as String?) ?? '';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: mintGreen,
                        foregroundColor: primaryGreen,
                        child: Text(
                          name.isEmpty ? '?' : name[0].toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'Student' : name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              email,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            if (phone.isNotEmpty)
                              Text(
                                phone,
                                style: const TextStyle(color: Colors.black54),
                              ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => _editProfile(data),
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const _GroupLabel('PREFERENCES'),
              Card(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.alarm_rounded,
                      title: 'Reminder preferences',
                      subtitle: 'Channels, timing and quiet hours',
                      onTap: () => _open(const ReminderPreferencesScreen()),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Reminders and alerts',
                      onTap: () => _open(const StudentNotificationsScreen()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _GroupLabel('SAFETY & SUPPORT'),
              Card(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.emergency_outlined,
                      title: 'Emergency support & contacts',
                      subtitle: 'Helplines and your own contacts',
                      onTap: () => _open(const EmergencySupportScreen()),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.call_rounded,
                      title: 'Crisis hotline',
                      subtitle: 'Call ${EmergencyNumbers.crisisHotline}',
                      onTap: _callHotline,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _GroupLabel('ACCOUNT'),
              Card(
                child: _SettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Log out',
                  onTap: _logout,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: .6,
        color: Colors.black54,
      ),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: primaryGreen),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

/// Edit-profile dialog. Owns and disposes its own controllers.
class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({required this.service, required this.data});

  final StudentProfileService service;
  final Map<String, dynamic> data;

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.data['fullName'] as String?);
    _phone = TextEditingController(text: widget.data['phoneNumber'] as String?);
    _whatsapp = TextEditingController(
      text: widget.data['whatsappNumber'] as String?,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  /// Phone numbers are optional here, but must look valid when filled in.
  String? _optionalPhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    if (!RegExp(r'^\+?[0-9 ]{7,15}$').hasMatch(v)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.update(
        fullName: _name.text,
        phoneNumber: _phone.text,
        whatsappNumber: _whatsapp.text,
      );
      if (mounted) Navigator.pop(context, 'Profile updated');
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'We could not save your profile. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: pageBackground,
      title: const Text('Edit profile'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthTextField(
                controller: _name,
                label: 'Full name',
                hint: 'Your name',
                icon: Icons.person_outline_rounded,
                validator: (v) => requiredValue(v, 'Name is required'),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _phone,
                label: 'Phone number',
                hint: '07X XXX XXXX',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _optionalPhone,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _whatsapp,
                label: 'WhatsApp number',
                hint: '07X XXX XXXX',
                icon: Icons.chat_outlined,
                keyboardType: TextInputType.phone,
                validator: _optionalPhone,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('SAVE'),
        ),
      ],
    );
  }
}
