import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare_wellness/services/booking_service.dart';
import 'package:mindcare_wellness/services/privacy_service.dart';

void main() {
  group('PrivacyService utility functions', () {
    test('generateRandomPseudonym produces expected format', () {
      final seededRandom = Random(42);
      final pseudonym = generateRandomPseudonym(random: seededRandom);

      expect(pseudonym, isNotEmpty);
      // Format: [Adjective][Noun][10-99]
      expect(RegExp(r'^[A-Z][a-zA-Z]+[0-9]{2}$').hasMatch(pseudonym), isTrue);
    });

    test('generateRandomPseudonym produces diverse aliases across iterations', () {
      final set = <String>{};
      for (var i = 0; i < 50; i++) {
        set.add(generateRandomPseudonym());
      }
      expect(set.length, greaterThan(25));
    });

    test('generatePasscode produces STU- prefix followed by 4 digits by default', () {
      final seededRandom = Random(100);
      final passcode = generatePasscode(random: seededRandom);

      expect(passcode.startsWith('STU-'), isTrue);
      final numberPart = passcode.replaceFirst('STU-', '');
      expect(numberPart.length, 4);
      expect(int.tryParse(numberPart), isNotNull);
    });

    test('generatePasscode respects custom prefix', () {
      final passcode = generatePasscode(prefix: 'CARE-');
      expect(passcode.startsWith('CARE-'), isTrue);
      final numberPart = passcode.replaceFirst('CARE-', '');
      expect(numberPart.length, 4);
      expect(int.tryParse(numberPart), isNotNull);
    });

    test('PrivacyService instance proxies produce valid pseudonyms and passcodes', () {
      final service = PrivacyService();
      expect(service.createPseudonym(), isNotEmpty);
      expect(service.createPasscode().startsWith('STU-'), isTrue);
    });
  });

  group('BookingService offline fallback and scheduling tests', () {
    test('fetchCounselors returns default curated counselors when offline', () async {
      final service = BookingService();
      final counselors = await service.fetchCounselors();

      expect(counselors, isNotEmpty);
      expect(counselors.length, greaterThanOrEqualTo(3));
      for (final c in counselors) {
        expect(c.id, isNotEmpty);
        expect(c.name, isNotEmpty);
        expect(c.availableSlots, isNotEmpty);
      }
    });

    test('getCounselorById finds existing default counselor', () async {
      final service = BookingService();
      final counselor = await service.getCounselorById('counselor_sarah');

      expect(counselor, isNotNull);
      expect(counselor!.name, 'Dr. Sarah Perera');
      expect(counselor.isConfidentialSupported, isTrue);
    });

    test('fetchAvailableSlots returns valid slot intervals', () async {
      final service = BookingService();
      final slots = await service.fetchAvailableSlots('counselor_sarah');

      expect(slots, isNotEmpty);
      expect(slots, contains('09:30 AM'));
      expect(slots, contains('11:00 AM'));
    });
  });
}
