import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare_wellness/models/student_model.dart';

void main() {
  test('student without alias displays the full name', () {
    const student = StudentModel(uid: 'student-1', alias: null, isAnonymous: false);

    expect(student.counselorDisplayName(fullName: 'John Perera'), 'John Perera');
  });

  test('student with alias displays only the alias when anonymous mode is enabled', () {
    const student = StudentModel(
      uid: 'student-1',
      alias: 'Student#4821',
      isAnonymous: true,
    );

    final label = student.counselorDisplayName(fullName: 'John Perera');

    expect(label, 'Student#4821');
    expect(label.contains('John Perera'), isFalse);
  });

  test('student with alias but anonymous mode off keeps the real name visible', () {
    const student = StudentModel(
      uid: 'student-1',
      alias: 'Student#4821',
      isAnonymous: false,
    );

    expect(student.counselorDisplayName(fullName: 'John Perera'), 'John Perera');
    expect(student.matchesCounselorSearch('student#4821', fullName: 'John Perera'), isFalse);
    expect(student.matchesCounselorSearch('john', fullName: 'John Perera'), isTrue);
  });

  test('student search matches alias or full name case-insensitively when anonymous mode is on', () {
    const student = StudentModel(
      uid: 'student-1',
      alias: 'Student#4821',
      isAnonymous: true,
    );

    expect(student.matchesCounselorSearch('john', fullName: 'John Perera'), isTrue);
    expect(student.matchesCounselorSearch('student#4821', fullName: 'John Perera'), isTrue);
    expect(student.matchesCounselorSearch('john perera', fullName: 'John Perera'), isTrue);
  });

  test('legacy student documents default to normal priority', () {
    const student = StudentModel(uid: 'legacy-student');

    expect(student.priorityLevel, 'normal');
    expect(student.isHighPriority, isFalse);
  });
}
