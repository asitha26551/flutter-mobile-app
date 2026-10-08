import 'package:flutter/material.dart';

import '../../models/privacy_settings_model.dart';
import '../../services/privacy_service.dart';

/// Screen 2: Privacy & Identity Controls Screen
/// Provides zero-data disclosure configuration, anonymous pseudonym customization,
/// cryptographic ID inspection, and consent toggles for MindCare Wellness students.
class PrivacyControlsScreen extends StatefulWidget {
  const PrivacyControlsScreen({
    this.privacyService,
    this.initialUid,
    super.key,
  });

  final PrivacyService? privacyService;
  final String? initialUid;

  @override
  State<PrivacyControlsScreen> createState() => _PrivacyControlsScreenState();
}

class _PrivacyControlsScreenState extends State<PrivacyControlsScreen> {
  late final PrivacyService _service;

  bool _isLoading = true;
  bool _isSaving = false;

  // Identity state
  String _currentPseudonym = 'SilentPanda42';
  String _passcode = 'STU-8821';
  String _cryptographicId = 'AD892-A';

  // Toggle states
  bool _hideRealName = true;
  bool _maskStudentId = true;
  bool _allowAnonymousNotes = true;
  bool _biometricLock = false;

  static const Color _emeraldGreen = Color(0xFF059669);
  static const Color _darkEmerald = Color(0xFF064E3B);
  static const Color _mintTint = Color(0xFFECFDF5);
  static const Color _mintBorder = Color(0xFFA7F3D0);

  @override
  void initState() {
    super.initState();
    _service = widget.privacyService ?? PrivacyService();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _service.getPrivacySettings(widget.initialUid);
      if (mounted) {
        setState(() {
          _hideRealName = settings.hideRealName;
          _maskStudentId = settings.maskStudentId;
          _allowAnonymousNotes = settings.allowAnonymousNotes;
          _biometricLock = settings.biometricLock;

          if (settings.currentPseudonym.isNotEmpty) {
            _currentPseudonym = settings.currentPseudonym;
          } else {
            _currentPseudonym = generateRandomPseudonym();
          }

          if (settings.passcode.isNotEmpty) {
            _passcode = settings.passcode;
          } else {
            _passcode = generatePasscode();
          }

          _computeCryptographicId();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _computeCryptographicId() {
    if (_passcode.startsWith('STU-')) {
      final code = _passcode.replaceFirst('STU-', '');
      _cryptographicId = 'AD$code-A';
    } else {
      _cryptographicId = 'AD892-A';
    }
  }

  void _randomizePseudonym() {
    final newAlias = generateRandomPseudonym();
    final newPasscode = generatePasscode();
    setState(() {
      _currentPseudonym = newAlias;
      _passcode = newPasscode;
      _computeCryptographicId();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated new pseudonym: $newAlias'),
        duration: const Duration(seconds: 2),
        backgroundColor: _darkEmerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openCustomizeDialog() async {
    final controller = TextEditingController(text: _currentPseudonym);
    final formKey = GlobalKey<FormState>();

    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.edit_outlined, color: _emeraldGreen, size: 22),
            SizedBox(width: 8),
            Text(
              'Customize Pseudonym',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter an anonymous alias that counselors will see during sessions:',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Pseudonym',
                  hintText: 'e.g. PeacefulBreeze99',
                  prefixIcon: const Icon(Icons.masks_outlined, color: _emeraldGreen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _emeraldGreen, width: 1.6),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 3) {
                    return 'Must be at least 3 characters';
                  }
                  if (val.trim().length > 24) {
                    return 'Cannot exceed 24 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: _emeraldGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Apply Alias'),
          ),
        ],
      ),
    );

    if (chosen != null && chosen.isNotEmpty) {
      setState(() {
        _currentPseudonym = chosen;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final updatedModel = PrivacySettingsModel(
        hideRealName: _hideRealName,
        maskStudentId: _maskStudentId,
        allowAnonymousNotes: _allowAnonymousNotes,
        biometricLock: _biometricLock,
        currentPseudonym: _currentPseudonym,
        passcode: _passcode,
      );

      await _service.savePrivacySettings(
        updatedModel,
        uid: widget.initialUid,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Privacy & Identity Settings updated securely.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: _emeraldGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Privacy & Identity Controls',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Reload settings',
            onPressed: _loadSettings,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _emeraldGreen),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
                children: [
                  // 1. TOP CARD: Dark Emerald Banner with Zero-Data Disclosure Badge
                  _buildTopBannerCard(),
                  const SizedBox(height: 18),

                  // 2. IDENTITY CONTROLS CARD: Active Pseudonym & Cryptographic ID
                  _buildIdentityControlsCard(),
                  const SizedBox(height: 22),

                  // 3. DATA CONSENT & PRIVACY CONTROLS TOGGLES
                  _buildSectionHeader('Data Consent & Privacy Controls'),
                  const SizedBox(height: 12),
                  _buildTogglesCard(),
                  const SizedBox(height: 26),

                  // 4. BOTTOM ACTION BUTTON: Full-width Emerald Green
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  /// 1. Top Card: Dark Emerald banner "100% Anonymous & Encrypted Session"
  /// with zero-data disclosure badge.
  Widget _buildTopBannerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF044E38),
            Color(0xFF065F46),
            Color(0xFF059669),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _emeraldGreen.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zero-data disclosure badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF6EE7B7),
                  size: 15,
                ),
                SizedBox(width: 6),
                Text(
                  'ZERO-DATA DISCLOSURE BADGE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 26,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '100% Anonymous & Encrypted Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.5,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Your identity, conversations, and clinical notes are end-to-end encrypted. University faculty and department personnel have zero access to your session records.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Identity Controls Card: Displays Active Pseudonym with Cryptographic ID
  /// and "Customize" / "Randomize" action buttons.
  Widget _buildIdentityControlsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _mintTint,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _mintBorder),
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      color: _emeraldGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Identity Controls',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _mintTint,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _mintBorder),
                ),
                child: const Text(
                  'ENCRYPTED',
                  style: TextStyle(
                    color: _darkEmerald,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Active Pseudonym Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVE PSEUDONYM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.masks_rounded,
                      color: _emeraldGreen,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _currentPseudonym,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 10),

                // Cryptographic ID Display
                Row(
                  children: [
                    const Icon(
                      Icons.tag_rounded,
                      size: 15,
                      color: _emeraldGreen,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'cryptographic_id: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _cryptographicId,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _darkEmerald,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: "Customize" and "Randomize"
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openCustomizeDialog,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Customize'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _randomizePseudonym,
                  icon: const Icon(Icons.casino_outlined, size: 17),
                  label: const Text('Randomize'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _darkEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Data Consent & Privacy Controls Toggles
  Widget _buildTogglesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildToggleTile(
            icon: Icons.badge_outlined,
            title: 'Hide Real Name on Bookings',
            subtitle: 'Withholds your student name on counselor schedules.',
            value: _hideRealName,
            onChanged: (val) => setState(() => _hideRealName = val),
          ),
          const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildToggleTile(
            icon: Icons.numbers_outlined,
            title: 'Mask Student ID',
            subtitle: 'Masks your university enrollment code (STU-***-89).',
            value: _maskStudentId,
            onChanged: (val) => setState(() => _maskStudentId = val),
          ),
          const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildToggleTile(
            icon: Icons.note_alt_outlined,
            title: 'Allow Anonymous Clinical Notes',
            subtitle: 'Keeps consultation notes strictly unlinked from academic files.',
            value: _allowAnonymousNotes,
            onChanged: (val) => setState(() => _allowAnonymousNotes = val),
          ),
          const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildToggleTile(
            icon: Icons.lock_clock_outlined,
            title: 'Biometric Lock on App Open',
            subtitle: 'Requires fingerprint, Face ID, or PIN to unlock privacy logs.',
            value: _biometricLock,
            onChanged: (val) => setState(() => _biometricLock = val),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: value ? _mintTint : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value ? _emeraldGreen : const Color(0xFF64748B),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeTrackColor: _mintBorder,
            activeThumbColor: _emeraldGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A),
        letterSpacing: 0.2,
      ),
    );
  }

  Future<void> _confirmResetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset Privacy Settings?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'This will reset your alias, passcode, and identity masks back to default zero-disclosure settings.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: _emeraldGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Reset Settings'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSaving = true);
      try {
        await _service.resetPrivacySettings(widget.initialUid);
        await _loadSettings();
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Privacy settings reset to defaults.'),
              backgroundColor: _emeraldGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reset settings: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// 4. Bottom Action Button: Full-width Emerald Green (#059669) & Reset Option
  Widget _buildSaveButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: FilledButton.styleFrom(
              backgroundColor: _emeraldGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              shadowColor: _emeraldGreen.withValues(alpha: 0.4),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Privacy Settings'),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _isSaving ? null : _confirmResetSettings,
          child: const Text(
            'Reset to Default Privacy Settings',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}
