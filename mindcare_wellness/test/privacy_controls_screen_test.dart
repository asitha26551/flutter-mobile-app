import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare_wellness/screens/privacy/privacy_controls_screen.dart';
import 'package:mindcare_wellness/services/privacy_service.dart';

class _FakePrivacyService extends PrivacyService {
  _FakePrivacyService({PrivacySettingsModel? initialSettings})
      : _settings = initialSettings ??
            const PrivacySettingsModel(
              hideRealName: true,
              maskStudentId: true,
              allowAnonymousNotes: true,
              biometricLock: false,
              currentPseudonym: 'SilentPanda42',
              passcode: 'STU-8821',
            );

  PrivacySettingsModel _settings;
  bool savedCalled = false;

  @override
  Future<PrivacySettingsModel> getPrivacySettings([String? uid]) async {
    return _settings;
  }

  @override
  Future<void> savePrivacySettings(
    PrivacySettingsModel settings, {
    String? uid,
  }) async {
    savedCalled = true;
    _settings = settings;
  }
}

void main() {
  testWidgets('PrivacyControlsScreen renders all required cards, toggles, and buttons', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeService = _FakePrivacyService();

    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyControlsScreen(privacyService: fakeService),
      ),
    );

    // Let async loading finish
    await tester.pumpAndSettle();

    // 1. Top Card: Dark Emerald banner & Zero-Data Disclosure Badge
    expect(find.text('100% Anonymous & Encrypted Session'), findsOneWidget);
    expect(find.text('ZERO-DATA DISCLOSURE BADGE'), findsOneWidget);

    // 2. Identity Controls Card
    expect(find.text('Identity Controls'), findsOneWidget);
    expect(find.text('ACTIVE PSEUDONYM'), findsOneWidget);
    expect(find.text('SilentPanda42'), findsOneWidget);
    expect(find.textContaining('cryptographic_id:'), findsOneWidget);
    expect(find.text('AD8821-A'), findsOneWidget);
    expect(find.text('Customize'), findsOneWidget);
    expect(find.text('Randomize'), findsOneWidget);

    // 3. Data Consent & Privacy Controls Toggles
    expect(find.text('Hide Real Name on Bookings'), findsOneWidget);
    expect(find.text('Mask Student ID'), findsOneWidget);
    expect(find.text('Allow Anonymous Clinical Notes'), findsOneWidget);
    expect(find.text('Biometric Lock on App Open'), findsOneWidget);

    // 4. Bottom Action Button: Save Privacy Settings
    expect(find.text('Save Privacy Settings'), findsOneWidget);
  });

  testWidgets('Randomize button generates a new pseudonym', (tester) async {
    final fakeService = _FakePrivacyService();

    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyControlsScreen(privacyService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SilentPanda42'), findsOneWidget);

    // Tap Randomize
    await tester.tap(find.text('Randomize'));
    await tester.pumpAndSettle();

    // SilentPanda42 should have been replaced by a freshly generated alias
    expect(find.text('SilentPanda42'), findsNothing);
  });

  testWidgets('Save Privacy Settings triggers save in PrivacyService', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeService = _FakePrivacyService();

    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyControlsScreen(privacyService: fakeService),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Save Privacy Settings
    await tester.tap(find.text('Save Privacy Settings'));
    await tester.pumpAndSettle();

    expect(fakeService.savedCalled, isTrue);
    expect(find.text('Privacy & Identity Settings updated securely.'), findsOneWidget);
  });
}
