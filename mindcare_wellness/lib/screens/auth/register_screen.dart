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
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _studentId = TextEditingController();
  final _faculty = TextEditingController();
  final _degree = TextEditingController();
  final _department = TextEditingController();
  final _intake = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _alternativePhone = TextEditingController();
  final _staffId = TextEditingController();
  final _counselorDepartment = TextEditingController();
  final _qualification = TextEditingController();
  final _qualificationInstitution = TextEditingController();
  final _registrationNumber = TextEditingController();
  final _registrationBody = TextEditingController();
  final _experience = TextEditingController();
  final _bio = TextEditingController();
  final _languages = TextEditingController();
  final _officeLocation = TextEditingController();
  late final AuthService _authService = widget.authService ?? AuthService();
  final _specializations = <String>{};
  final _sessionTypes = <String>{};
  String _role = 'student';
  String _academicYear = 'Year 1';
  bool _sameWhatsapp = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _busy = false;

  static const _specializationOptions = [
    'Academic Stress',
    'Anxiety',
    'Depression',
    'Relationship Issues',
    'Family Issues',
    'Stress Management',
    'Grief and Loss',
    'Career Guidance',
    'Personal Development',
    'Student Adjustment',
    'Other',
  ];
  static const _sessionOptions = [
    'In-person',
    'Audio call',
    'Video call',
    'Chat',
  ];
  static const _yearOptions = [
    'Year 1',
    'Year 2',
    'Year 3',
    'Year 4',
    'Postgraduate',
    'Other',
  ];

  List<TextEditingController> get _controllers => [
    _name,
    _email,
    _password,
    _confirm,
    _studentId,
    _faculty,
    _degree,
    _department,
    _intake,
    _phone,
    _whatsapp,
    _alternativePhone,
    _staffId,
    _counselorDepartment,
    _qualification,
    _qualificationInstitution,
    _registrationNumber,
    _registrationBody,
    _experience,
    _bio,
    _languages,
    _officeLocation,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _phoneValidator(String? value, {bool required = true}) {
    if (!required && (value == null || value.trim().isEmpty)) return null;
    if (value == null || value.trim().isEmpty)
      return 'Phone number is required';
    if (!RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch(value.trim()))
      return 'Enter a valid phone number';
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Years of experience is required';
    if (int.tryParse(value.trim()) == null)
      return 'Enter a valid number of years';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == 'counselor' &&
        (_specializations.isEmpty || _sessionTypes.isEmpty)) {
      _showMessage(
        'Select at least one specialization and session type.',
        isError: true,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      if (_role == 'student') {
        await _authService.registerStudent(
          fullName: _name.text,
          email: _email.text,
          password: _password.text,
          studentData: {
            'studentId': _studentId.text.trim(),
            'faculty': _faculty.text.trim(),
            'department': _department.text.trim(),
            'degreeProgram': _degree.text.trim(),
            'academicYear': _academicYear,
            'intake': _intake.text.trim(),
            'phoneNumber': _phone.text.trim(),
            'whatsappNumber': (_sameWhatsapp ? _phone.text : _whatsapp.text)
                .trim(),
            'alternativePhone': _alternativePhone.text.trim(),
          },
        );
      } else {
        await _authService.registerCounselor(
          fullName: _name.text,
          email: _email.text,
          password: _password.text,
          counselorData: {
            'staffId': _staffId.text.trim(),
            'department': _counselorDepartment.text.trim(),
            'qualification': _qualification.text.trim(),
            'qualificationInstitution': _qualificationInstitution.text.trim(),
            'registrationNumber': _registrationNumber.text.trim(),
            'registrationBody': _registrationBody.text.trim(),
            'specializations': _specializations.toList(),
            'yearsOfExperience': int.parse(_experience.text.trim()),
            'professionalBio': _bio.text.trim(),
            'languages': _languages.text.trim(),
            'officeLocation': _officeLocation.text.trim(),
            'sessionTypes': _sessionTypes.toList(),
            'phoneNumber': _phone.text.trim(),
            'whatsappNumber': (_sameWhatsapp ? _phone.text : _whatsapp.text)
                .trim(),
            'alternativePhone': _alternativePhone.text.trim(),
          },
        );
      }
      if (mounted)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(authService: _authService),
          ),
          (route) => false,
        );
    } catch (error) {
      if (mounted) _showMessage(authErrorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : primaryGreen,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Spacer(),
                const BrandMark(),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Create your account',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              'Join MindCare Wellness as a student or counselor',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            _roleSelector(),
            const SizedBox(height: 24),
            _sectionTitle('Personal information'),
            AuthTextField(
              controller: _name,
              label: 'Full name',
              hint: 'Your full name',
              icon: Icons.person_outline_rounded,
              validator: (value) =>
                  requiredValue(value, 'Full name is required'),
            ),
            const SizedBox(height: 14),
            if (_role == 'student')
              ..._studentFields()
            else
              ..._counselorFields(),
            _sectionTitle('Contact information'),
            AuthTextField(
              controller: _phone,
              label: 'Mobile phone number',
              hint: '+94 77 123 4567',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: _phoneValidator,
            ),
            const SizedBox(height: 14),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _sameWhatsapp,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _sameWhatsapp = value ?? false),
              title: const Text(
                'WhatsApp number is the same as my phone number',
                style: TextStyle(fontSize: 13),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (!_sameWhatsapp) ...[
              AuthTextField(
                controller: _whatsapp,
                label: 'WhatsApp number',
                hint: '+94 77 123 4567',
                icon: Icons.chat_outlined,
                keyboardType: TextInputType.phone,
                validator: _phoneValidator,
              ),
              const SizedBox(height: 14),
            ],
            AuthTextField(
              controller: _alternativePhone,
              label: 'Alternative phone (optional)',
              hint: 'Another way to reach you',
              icon: Icons.phone_callback_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) => _phoneValidator(value, required: false),
            ),
            _sectionTitle('Account information'),
            AuthTextField(
              controller: _email,
              label: _role == 'student'
                  ? 'University email address'
                  : 'Professional / university email',
              hint: 'you@university.edu',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: emailValue,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _password,
              label: 'Password',
              hint: 'At least 8 characters',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              onToggleObscure: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              validator: passwordValue,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _confirm,
              label: 'Confirm password',
              hint: 'Re-enter your password',
              icon: Icons.lock_reset_outlined,
              obscureText: _obscureConfirm,
              onToggleObscure: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (value) =>
                  value != _password.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: mintGreen.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _role == 'counselor'
                          ? 'Counselor accounts remain pending until an authorized administrator approves the application.'
                          : 'Your information stays private and secure. We will send a verification email after sign up.',
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: _role == 'counselor'
                  ? 'SUBMIT APPLICATION  →'
                  : 'CREATE STUDENT ACCOUNT  →',
              onPressed: _submit,
              busy: _busy,
            ),
            const SizedBox(height: 18),
            Center(
              child: Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  children: [
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: _busy
                            ? null
                            : () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              ),
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleSelector() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: _roleChoice('student', 'Student', Icons.school_outlined),
        ),
        Expanded(
          child: _roleChoice(
            'counselor',
            'Counselor',
            Icons.support_agent_rounded,
          ),
        ),
      ],
    ),
  );

  Widget _roleChoice(String value, String label, IconData icon) => ChoiceChip(
    label: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(label)],
    ),
    selected: _role == value,
    onSelected: _busy ? null : (_) => setState(() => _role = value),
    selectedColor: mintGreen,
    backgroundColor: Colors.transparent,
    side: BorderSide.none,
    labelStyle: TextStyle(
      color: _role == value ? primaryGreen : Colors.black54,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: primaryGreen,
        fontSize: 15,
      ),
    ),
  );

  List<Widget> _studentFields() => [
    AuthTextField(
      controller: _studentId,
      label: 'Student ID / registration number',
      hint: 'e.g. STU-2024-8891',
      icon: Icons.badge_outlined,
      validator: (value) => requiredValue(value, 'Student ID is required'),
    ),
    const SizedBox(height: 14),
    AuthTextField(
      controller: _faculty,
      label: 'Faculty / school',
      hint: 'Your faculty or school',
      icon: Icons.account_balance_outlined,
      validator: (value) => requiredValue(value, 'Faculty is required'),
    ),
    const SizedBox(height: 14),
    AuthTextField(
      controller: _degree,
      label: 'Degree / programme',
      hint: 'Your degree programme',
      icon: Icons.menu_book_outlined,
      validator: (value) =>
          requiredValue(value, 'Degree programme is required'),
    ),
    const SizedBox(height: 14),
    DropdownButtonFormField<String>(
      initialValue: _academicYear,
      decoration: const InputDecoration(
        labelText: 'Academic year / study year',
        prefixIcon: Icon(Icons.calendar_today_outlined),
      ),
      items: _yearOptions
          .map((year) => DropdownMenuItem(value: year, child: Text(year)))
          .toList(),
      onChanged: _busy
          ? null
          : (value) => setState(() => _academicYear = value ?? _academicYear),
    ),
    const SizedBox(height: 14),
    AuthTextField(
      controller: _department,
      label: 'Department (optional)',
      hint: 'Your department',
      icon: Icons.account_tree_outlined,
    ),
    const SizedBox(height: 14),
    AuthTextField(
      controller: _intake,
      label: 'Intake / batch (optional)',
      hint: 'e.g. 2024 September',
      icon: Icons.groups_outlined,
    ),
  ];

  List<Widget> _counselorFields() => [
    AuthTextField(
      controller: _staffId,
      label: 'Counselor / staff ID',
      hint: 'Your university staff ID',
      icon: Icons.badge_outlined,
      validator: (value) =>
          requiredValue(value, 'Counselor or staff ID is required'),
    ),
    const SizedBox(height: 14),
    AuthTextField(
      controller: _counselorDepartment,
      label: 'Department / counseling unit',
      hint: 'Your counseling department',
      icon: Icons.account_balance_outlined,
      validator: (value) => requiredValue(value, 'Department is required'),
    ),
    const SizedBox(height: 14),
    AuthTextField(
      controller: _qualification,
      label: 'Highest professional qualification',
      hint: 'e.g. MSc in Counseling Psychology',
      icon: Icons.school_outlined,
      validator: (value) => requiredValue(value, 'Qualification is required'),
    ),
    const SizedBox(height: 14),
    AuthTextField(
      controller: _qualificationInstitution,
      label: 'Qualification institution',
      hint: 'Where it was obtained',
      icon: Icons.account_balance_outlined,
      validator: (value) =>
          requiredValue(value, 'Qualification institution is required'),
    ),
    const SizedBox(height: 14),
    AuthTextField(
      controller: _experience,
      label: 'Years of professional experience',
      hint: 'e.g. 5',
      icon: Icons.timelapse_outlined,
      keyboardType: TextInputType.number,
      validator: _numberValidator,
    ),
    const SizedBox(height: 14),
    AuthTextField(
      controller: _registrationNumber,
      label: 'Registration / licence number (optional)',
      hint: 'Professional registration number',
      icon: Icons.verified_outlined,
    ),
    const SizedBox(height: 14),
    AuthTextField(
      controller: _registrationBody,
      label: 'Registration body (optional)',
      hint: 'Professional registration body',
      icon: Icons.gavel_outlined,
    ),
    const SizedBox(height: 14),
    AuthTextField(
      controller: _bio,
      label: 'Professional bio',
      hint: 'A short description of your practice',
      icon: Icons.notes_outlined,
      validator: (value) =>
          requiredValue(value, 'Professional bio is required'),
    ),
    const SizedBox(height: 14),
    AuthTextField(
      controller: _languages,
      label: 'Languages spoken (optional)',
      hint: 'e.g. English, Sinhala',
      icon: Icons.translate_outlined,
    ),
    const SizedBox(height: 14),
    AuthTextField(
      controller: _officeLocation,
      label: 'Office / location (optional)',
      hint: 'Consultation location',
      icon: Icons.location_on_outlined,
    ),
    const SizedBox(height: 14),
    _multiSelect(
      'Main counseling specializations',
      _specializationOptions,
      _specializations,
    ),
    const SizedBox(height: 14),
    _multiSelect('Session types supported', _sessionOptions, _sessionTypes),
  ];

  Widget _multiSelect(
    String title,
    List<String> options,
    Set<String> selected,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: options
            .map(
              (option) => FilterChip(
                label: Text(option),
                selected: selected.contains(option),
                onSelected: _busy
                    ? null
                    : (value) => setState(
                        () => value
                            ? selected.add(option)
                            : selected.remove(option),
                      ),
                selectedColor: mintGreen,
              ),
            )
            .toList(),
      ),
    ],
  );
}
