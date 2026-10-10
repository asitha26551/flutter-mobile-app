import 'package:flutter/material.dart';

import '../../models/reminder_preference_model.dart';
import '../../services/reminder_service.dart';
import '../../services/student_notification_service.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/common/error_message.dart';
import '../../widgets/common/loading.dart';

/// Reminder Preferences (FR-05): channels, lead time and quiet hours.
/// CRUD on one document: read (load), create/update (save), delete (reset).
class ReminderPreferencesScreen extends StatefulWidget {
  const ReminderPreferencesScreen({
    this.service,
    this.notificationService,
    super.key,
  });

  final ReminderService? service;
  final StudentNotificationService? notificationService;

  @override
  State<ReminderPreferencesScreen> createState() =>
      _ReminderPreferencesScreenState();
}

class _ReminderPreferencesScreenState extends State<ReminderPreferencesScreen> {
  late final ReminderService _service = widget.service ?? ReminderService();
  late final StudentNotificationService _notifications =
      widget.notificationService ?? StudentNotificationService();

  ReminderPreferences? _prefs;
  bool _loadFailed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _load() async {
    try {
      final loaded = await _service.load();
      if (mounted) setState(() => _prefs = loaded);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  void _change(ReminderPreferences updated) => setState(() => _prefs = updated);

  Future<void> _pickTime({required bool start}) async {
    final current = _prefs!;
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(start ? current.quietStart : current.quietEnd),
    );
    if (picked == null || !mounted) return;
    _change(
      start
          ? current.copyWith(quietStart: _formatTime(picked))
          : current.copyWith(quietEnd: _formatTime(picked)),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _service.save(_prefs!);
      _snack('Preferences saved');
    } catch (_) {
      _snack('We could not save your preferences. Please try again.');
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _reset() async {
    try {
      await _service.reset();
      if (mounted) _change(const ReminderPreferences());
      _snack('Preferences reset to defaults');
    } catch (_) {
      _snack('We could not reset your preferences. Please try again.');
    }
  }

  Future<void> _sendTest() async {
    try {
      await _notifications.create(
        title: 'Test reminder',
        body: 'Reminders are working. This is a test notification.',
      );
      _snack('Test reminder sent. Check your notifications.');
    } catch (_) {
      _snack('We could not send the test reminder.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = _prefs;
    Widget body;
    if (_loadFailed) {
      body = const ErrorMessage(
        message: 'We could not load your preferences. Please try again.',
      );
    } else if (prefs == null) {
      body = const LoadingWidget();
    } else {
      body = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionTitle('Notification channels'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('WhatsApp'),
                  value: prefs.whatsapp,
                  onChanged: (v) => _change(prefs.copyWith(whatsapp: v)),
                ),
                SwitchListTile(
                  title: const Text('SMS notifications'),
                  value: prefs.sms,
                  onChanged: (v) => _change(prefs.copyWith(sms: v)),
                ),
                SwitchListTile(
                  title: const Text('Email reminders'),
                  value: prefs.email,
                  onChanged: (v) => _change(prefs.copyWith(email: v)),
                ),
                SwitchListTile(
                  title: const Text('Push notification'),
                  value: prefs.push,
                  onChanged: (v) => _change(prefs.copyWith(push: v)),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              'Push reminders appear on this device. SMS, WhatsApp and email '
              'choices are saved as preferences only in this version.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Remind me before'),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 15, label: Text('15 min')),
                ButtonSegment(value: 60, label: Text('1 hour')),
                ButtonSegment(value: 1440, label: Text('1 day')),
              ],
              selected: {prefs.remindBeforeMinutes},
              onSelectionChanged: (s) =>
                  _change(prefs.copyWith(remindBeforeMinutes: s.first)),
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Quiet hours'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.bedtime_outlined),
                  title: const Text('Quiet hours'),
                  subtitle: const Text('Mute reminders during rest time'),
                  value: prefs.quietHoursEnabled,
                  onChanged: (v) => _change(prefs.copyWith(quietHoursEnabled: v)),
                ),
                if (prefs.quietHoursEnabled) ...[
                  ListTile(
                    title: const Text('Start'),
                    trailing: Text(
                      _parseTime(prefs.quietStart).format(context),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () => _pickTime(start: true),
                  ),
                  ListTile(
                    title: const Text('End'),
                    trailing: Text(
                      _parseTime(prefs.quietEnd).format(context),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () => _pickTime(start: false),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _saving ? null : _reset,
                    child: const Text('RESET'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'SAVE CHANGES',
                  busy: _saving,
                  onPressed: _save,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _sendTest,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Send test reminder'),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text(
          'Reminder Preferences',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: body,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
    ),
  );
}

/// "HH:mm" (24 hour) -> TimeOfDay. Bad values fall back to 00:00.
TimeOfDay _parseTime(String value) {
  final parts = value.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  return TimeOfDay(
    hour: hour.clamp(0, 23).toInt(),
    minute: minute.clamp(0, 59).toInt(),
  );
}

String _formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';
