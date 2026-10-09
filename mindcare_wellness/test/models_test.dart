import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare_wellness/models/appointment_model.dart';
import 'package:mindcare_wellness/models/counselor_models.dart';
import 'package:mindcare_wellness/services/privacy_service.dart';

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

  group('AppointmentModel', () {
    test('instantiates with all required fields', () {
      final start = DateTime(2026, 10, 5, 10, 0);
      final end = DateTime(2026, 10, 5, 10, 50);
      final appointment = AppointmentModel(
        id: 'apt001',
        studentId: 'CalmRiver',
        counselorId: 'c101',
        startAt: start,
        endAt: end,
        sessionType: 'Online Video',
        status: 'confirmed',
        reason: 'Exam anxiety and stress',
        studentNotes: 'Passcode: STU-9921',
      );

      expect(appointment.id, 'apt001');
      expect(appointment.studentId, 'CalmRiver');
      expect(appointment.counselorId, 'c101');
      expect(appointment.startAt, start);
      expect(appointment.endAt, end);
      expect(appointment.sessionType, 'Online Video');
      expect(appointment.status, 'confirmed');
      expect(appointment.reason, 'Exam anxiety and stress');
      expect(appointment.studentNotes, 'Passcode: STU-9921');
      expect(appointment.isUpcoming, isTrue);
      expect(appointment.isCancelled, isFalse);
    });

    test('fromMap and toFirestore handle dates and serialization', () {
      final targetDate = DateTime(2026, 10, 15, 14, 30);
      final endDate = DateTime(2026, 10, 15, 15, 20);

      final map = {
        'studentId': 'SilentPanda42',
        'counselorId': 'c1',
        'startAt': Timestamp.fromDate(targetDate),
        'endAt': Timestamp.fromDate(endDate),
        'sessionType': 'video',
        'status': 'confirmed',
        'reason': 'Stress',
        'studentNotes': 'Passcode: STU-1234',
      };

      final appointment = AppointmentModel.fromMap('apt123', map);
      expect(appointment.id, 'apt123');
      expect(appointment.studentId, 'SilentPanda42');
      expect(appointment.startAt, targetDate);
      expect(appointment.endAt, endDate);
      expect(appointment.sessionType, 'video');

      final exported = appointment.toFirestore();
      expect(exported['studentId'], 'SilentPanda42');
      expect(exported['counselorId'], 'c1');
      expect(exported['sessionType'], 'video');
      expect(exported['status'], 'confirmed');
      expect(exported['reason'], 'Stress');
      expect(exported['studentNotes'], 'Passcode: STU-1234');
    });

    test('copyWith updates specified fields only', () {
      final start = DateTime(2026, 10, 5, 9, 0);
      final appointment = AppointmentModel(
        id: 'apt1',
        studentId: 'student_1',
        counselorId: 'c1',
        startAt: start,
        endAt: start.add(const Duration(minutes: 50)),
        sessionType: 'video',
        status: 'confirmed',
      );

      final updated = appointment.copyWith(
        reason: 'Focusing on sleep quality',
        status: 'cancelled',
        cancellationReason: 'Student conflict',
      );

      expect(updated.id, 'apt1');
      expect(updated.reason, 'Focusing on sleep quality');
      expect(updated.status, 'cancelled');
      expect(updated.isCancelled, isTrue);
      expect(updated.cancellationReason, 'Student conflict');
      expect(updated.studentId, 'student_1');
    });
  });
}
