import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare_wellness/models/booking_model.dart';
import 'package:mindcare_wellness/models/counselor_model.dart';
import 'package:mindcare_wellness/models/privacy_settings_model.dart';

void main() {
  group('PrivacySettingsModel', () {
    test('default instantiation has correct defaults', () {
      const model = PrivacySettingsModel();
      expect(model.hideRealName, isFalse);
      expect(model.maskStudentId, isFalse);
      expect(model.allowAnonymousNotes, isTrue);
      expect(model.biometricLock, isFalse);
      expect(model.currentPseudonym, isEmpty);
      expect(model.passcode, isEmpty);
    });

    test('fromJson and toJson are symmetrical and null safe', () {
      final json = {
        'hideRealName': true,
        'maskStudentId': true,
        'allowAnonymousNotes': false,
        'biometricLock': true,
        'currentPseudonym': 'EmeraldFox',
        'passcode': '4821',
      };

      final model = PrivacySettingsModel.fromJson(json);
      expect(model.hideRealName, isTrue);
      expect(model.maskStudentId, isTrue);
      expect(model.allowAnonymousNotes, isFalse);
      expect(model.biometricLock, isTrue);
      expect(model.currentPseudonym, 'EmeraldFox');
      expect(model.passcode, '4821');

      expect(model.toJson(), json);
      expect(model.toFirestore(), json);

      final emptyFromJson = PrivacySettingsModel.fromJson(null);
      expect(emptyFromJson, const PrivacySettingsModel());
    });

    test('copyWith updates specified fields only', () {
      const initial = PrivacySettingsModel(currentPseudonym: 'OldAlias');
      final updated = initial.copyWith(
        currentPseudonym: 'NewAlias',
        biometricLock: true,
      );

      expect(updated.currentPseudonym, 'NewAlias');
      expect(updated.biometricLock, isTrue);
      expect(updated.hideRealName, isFalse);
    });

    test('equality and hashCode work as expected', () {
      const a = PrivacySettingsModel(currentPseudonym: 'Same');
      const b = PrivacySettingsModel(currentPseudonym: 'Same');
      const c = PrivacySettingsModel(currentPseudonym: 'Different');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('CounselorModel', () {
    test('instantiates with non-null values and defaults', () {
      const counselor = CounselorModel(
        id: 'c1',
        name: 'Dr. Sarah Smith',
      );
      expect(counselor.id, 'c1');
      expect(counselor.name, 'Dr. Sarah Smith');
      expect(counselor.rating, '0.0');
      expect(counselor.reviewCount, 0);
      expect(counselor.tags, isEmpty);
      expect(counselor.availableSlots, isEmpty);
      expect(counselor.isConfidentialSupported, isTrue);
    });

    test('fromJson and toJson handle complete and partial data', () {
      final json = {
        'id': 'c101',
        'name': 'Dr. Emily Vance',
        'title': 'Clinical Psychologist',
        'rating': '4.95',
        'reviewCount': 84,
        'image': 'https://example.com/avatar.jpg',
        'tags': ['Anxiety', 'Burnout', 'Mindfulness'],
        'availableSlots': ['09:00 AM', '11:00 AM', '03:00 PM'],
        'isConfidentialSupported': true,
      };

      final model = CounselorModel.fromJson(json);
      expect(model.id, 'c101');
      expect(model.name, 'Dr. Emily Vance');
      expect(model.title, 'Clinical Psychologist');
      expect(model.rating, '4.95');
      expect(model.reviewCount, 84);
      expect(model.tags, ['Anxiety', 'Burnout', 'Mindfulness']);
      expect(model.availableSlots, ['09:00 AM', '11:00 AM', '03:00 PM']);
      expect(model.isConfidentialSupported, isTrue);

      expect(model.toJson(), json);
      expect(model.toFirestore(), json);
    });

    test('copyWith updates specified fields only', () {
      const counselor = CounselorModel(
        id: 'c1',
        name: 'Jane Doe',
        rating: '4.5',
      );
      final updated = counselor.copyWith(
        rating: '4.9',
        reviewCount: 12,
        tags: ['Grief'],
      );

      expect(updated.rating, '4.9');
      expect(updated.reviewCount, 12);
      expect(updated.tags, ['Grief']);
      expect(updated.name, 'Jane Doe');
    });

    test('supports alternative key fallbacks (specializations, slots)', () {
      final raw = {
        'uid': 'c-alt',
        'fullName': 'Dr. Alex',
        'specializations': ['Stress', 'Exam Anxiety'],
        'slots': ['10:00 AM'],
      };
      final model = CounselorModel.fromJson(raw);
      expect(model.id, 'c-alt');
      expect(model.name, 'Dr. Alex');
      expect(model.tags, ['Stress', 'Exam Anxiety']);
      expect(model.availableSlots, ['10:00 AM']);
    });
  });

  group('BookingModel', () {
    test('instantiates with all required fields', () {
      final now = DateTime(2026, 10, 5, 10, 0);
      final booking = BookingModel(
        bookingId: 'b001',
        counselorId: 'c101',
        counselorName: 'Dr. Emily Vance',
        sessionFormat: 'Online Video',
        date: now,
        timeSlot: '10:00 AM - 11:00 AM',
        pseudonym: 'CalmRiver',
        passcode: '9921',
        reason: 'Exam anxiety and stress',
        isAnonymousMode: true,
      );

      expect(booking.bookingId, 'b001');
      expect(booking.counselorId, 'c101');
      expect(booking.counselorName, 'Dr. Emily Vance');
      expect(booking.sessionFormat, 'Online Video');
      expect(booking.date, now);
      expect(booking.timeSlot, '10:00 AM - 11:00 AM');
      expect(booking.pseudonym, 'CalmRiver');
      expect(booking.passcode, '9921');
      expect(booking.reason, 'Exam anxiety and stress');
      expect(booking.isAnonymousMode, isTrue);
    });

    test('fromJson correctly parses ISO date, Timestamp, and millis', () {
      final targetDate = DateTime(2026, 10, 15, 14, 30);

      // ISO String
      final jsonIso = {
        'bookingId': 'b-iso',
        'counselorId': 'c1',
        'counselorName': 'Dr. Name',
        'sessionFormat': 'In-Person',
        'date': targetDate.toIso8601String(),
        'timeSlot': '02:30 PM',
        'isAnonymousMode': false,
      };
      final modelIso = BookingModel.fromJson(jsonIso);
      expect(modelIso.date, targetDate);

      // Timestamp
      final jsonTimestamp = {
        'bookingId': 'b-ts',
        'counselorId': 'c1',
        'counselorName': 'Dr. Name',
        'sessionFormat': 'Confidential Chat',
        'date': Timestamp.fromDate(targetDate),
        'timeSlot': '02:30 PM',
        'isAnonymousMode': true,
      };
      final modelTimestamp = BookingModel.fromJson(jsonTimestamp);
      expect(modelTimestamp.date, targetDate);

      // Milliseconds
      final jsonMillis = {
        'bookingId': 'b-ms',
        'counselorId': 'c1',
        'counselorName': 'Dr. Name',
        'sessionFormat': 'Online Video',
        'date': targetDate.millisecondsSinceEpoch,
        'timeSlot': '02:30 PM',
      };
      final modelMillis = BookingModel.fromJson(jsonMillis);
      expect(modelMillis.date, targetDate);
    });

    test('toJson and toFirestore export appropriate formats', () {
      final targetDate = DateTime(2026, 10, 5, 9, 0);
      final booking = BookingModel(
        bookingId: 'b123',
        counselorId: 'c99',
        counselorName: 'Dr. Jane',
        sessionFormat: 'Online Video',
        date: targetDate,
        timeSlot: '09:00 AM',
      );

      final json = booking.toJson();
      expect(json['date'], targetDate.toIso8601String());

      final firestoreData = booking.toFirestore();
      expect(firestoreData['date'], isA<Timestamp>());
      expect((firestoreData['date'] as Timestamp).toDate(), targetDate);
    });

    test('copyWith updates specified fields only', () {
      final now = DateTime(2026, 10, 5);
      final booking = BookingModel(
        bookingId: 'b1',
        counselorId: 'c1',
        counselorName: 'Dr. One',
        sessionFormat: 'Online Video',
        date: now,
        timeSlot: '10:00 AM',
        pseudonym: 'OldAlias',
      );

      final updated = booking.copyWith(
        pseudonym: 'NewAlias',
        reason: 'Focusing on sleep quality',
      );

      expect(updated.pseudonym, 'NewAlias');
      expect(updated.reason, 'Focusing on sleep quality');
      expect(updated.bookingId, 'b1');
      expect(updated.counselorName, 'Dr. One');
    });

    test('toString masks sensitive passcode', () {
      final booking = BookingModel(
        bookingId: 'b1',
        counselorId: 'c1',
        counselorName: 'Dr. One',
        sessionFormat: 'Online',
        date: DateTime.now(),
        timeSlot: '10:00 AM',
        passcode: '7733',
      );

      expect(booking.toString().contains('passcode: ***'), isTrue);
      expect(booking.toString().contains('7733'), isFalse);
    });
  });
}
