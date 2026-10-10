import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/emergency_contact_model.dart';
import '../../services/emergency_service.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_message.dart';
import '../../widgets/common/loading.dart';

/// National numbers are kept in ONE place so they are easy to verify/change.
class EmergencyNumbers {
  static const crisisHotline = '1926'; // NIMH National Mental Health Helpline
  static const police = '119'; // Sri Lanka Police emergency
}

/// Emergency Support (FR-12): one-tap crisis call + the student's own
/// emergency contacts (create / read / update / delete).
class EmergencySupportScreen extends StatefulWidget {
  const EmergencySupportScreen({
    this.service,
    this.onChatWithCounselor,
    super.key,
  });

  final EmergencyService? service;

  /// Where "Chat with a Counselor" should go (the group's booking/chat screen).
  final VoidCallback? onChatWithCounselor;

  @override
  State<EmergencySupportScreen> createState() => _EmergencySupportScreenState();
}

class _EmergencySupportScreenState extends State<EmergencySupportScreen> {
  late final EmergencyService _service = widget.service ?? EmergencyService();
  late final Stream<List<EmergencyContact>> _contacts = _service.mine();

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _call(String number) async {
    try {
      final launched = await launchUrl(Uri(scheme: 'tel', path: number));
      if (!launched) _snack('Could not open the phone app. Please dial $number.');
    } catch (_) {
      _snack('Could not open the phone app. Please dial $number.');
    }
  }

  Future<void> _showContactDialog({EmergencyContact? existing}) async {
    final message = await showDialog<String>(
      context: context,
      builder: (_) => _ContactDialog(service: _service, existing: existing),
    );
    if (message != null) _snack(message);
  }

  Future<void> _confirmDelete(EmergencyContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text('${contact.name} will be removed from your contacts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.delete(contact.id);
      _snack('Contact deleted');
    } catch (_) {
      _snack('We could not delete the contact. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text(
          'Emergency Support',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Reassurance banner.
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're not alone right now",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Free, confidential help is one call away. '
                  'If you are in immediate danger, call ${EmergencyNumbers.police}.',
                  style: TextStyle(color: Colors.white, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Primary action: visually dominant (usability issue U-03).
          SizedBox(
            height: 58,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () => _call(EmergencyNumbers.crisisHotline),
              icon: const Icon(Icons.call_rounded),
              label: const Text('CALL CRISIS HOTLINE NOW'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed:
                  widget.onChatWithCounselor ??
                  () => _snack('Counselor chat is available from your booked sessions.'),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Chat with a Counselor'),
            ),
          ),
          const SizedBox(height: 26),

          const Text(
            'National support',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          _NumberTile(
            icon: Icons.psychology_alt_outlined,
            title: 'National Mental Health Helpline',
            subtitle: 'NIMH · ${EmergencyNumbers.crisisHotline}',
            onCall: () => _call(EmergencyNumbers.crisisHotline),
          ),
          _NumberTile(
            icon: Icons.local_police_outlined,
            title: 'Police emergency',
            subtitle: EmergencyNumbers.police,
            onCall: () => _call(EmergencyNumbers.police),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'My emergency contacts',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showContactDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<EmergencyContact>>(
            stream: _contacts,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const ErrorMessage(
                  message: 'We could not load your contacts. Please try again.',
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: LoadingWidget(),
                );
              }
              final contacts = snapshot.data!;
              if (contacts.isEmpty) {
                return const EmptyState(
                  message: 'No emergency contacts added yet.',
                );
              }
              return Column(
                children: [
                  for (final c in contacts)
                    _ContactTile(
                      contact: c,
                      onCall: () => _call(c.phoneNumber),
                      onEdit: () => _showContactDialog(existing: c),
                      onDelete: () => _confirmDelete(c),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onCall,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: mintGreen,
          foregroundColor: primaryGreen,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: IconButton(
          tooltip: 'Call $title',
          onPressed: onCall,
          icon: const Icon(Icons.call_rounded, color: primaryGreen),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.onCall,
    required this.onEdit,
    required this.onDelete,
  });

  final EmergencyContact contact;
  final VoidCallback onCall;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: mintGreen,
          foregroundColor: primaryGreen,
          child: Icon(Icons.person_outline_rounded),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${contact.relationship} · ${contact.phoneNumber}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Call ${contact.name}',
              onPressed: onCall,
              icon: const Icon(Icons.call_rounded, color: primaryGreen),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Add / edit dialog. It owns its controllers and disposes them only when
/// the dialog is really removed from the tree (fixes the "used after being
/// disposed" error).
class _ContactDialog extends StatefulWidget {
  const _ContactDialog({required this.service, this.existing});

  final EmergencyService service;
  final EmergencyContact? existing;

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _relationship;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name);
    _phone = TextEditingController(text: widget.existing?.phoneNumber);
    _relationship = TextEditingController(text: widget.existing?.relationship);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relationship.dispose();
    super.dispose();
  }

  String? _phoneValue(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Phone number is required';
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
      final existing = widget.existing;
      if (existing == null) {
        await widget.service.add(
          name: _name.text,
          phoneNumber: _phone.text,
          relationship: _relationship.text,
        );
      } else {
        await widget.service.update(
          EmergencyContact(
            id: existing.id,
            name: _name.text,
            phoneNumber: _phone.text,
            relationship: _relationship.text,
          ),
        );
      }
      if (mounted) {
        Navigator.pop(
          context,
          existing == null ? 'Contact added' : 'Contact updated',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'We could not save the contact. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: pageBackground,
      title: Text(widget.existing == null ? 'Add contact' : 'Edit contact'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthTextField(
                controller: _name,
                label: 'Name',
                hint: 'e.g. Amma',
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
                validator: _phoneValue,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _relationship,
                label: 'Relationship',
                hint: 'e.g. Parent, Friend',
                icon: Icons.favorite_border_rounded,
                validator: (v) => requiredValue(v, 'Relationship is required'),
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
