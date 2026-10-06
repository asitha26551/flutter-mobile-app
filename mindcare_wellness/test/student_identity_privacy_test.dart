import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare_wellness/models/student_model.dart';

void main() {
  test('student without alias displays the full name', () {
    const student = StudentModel(uid: 'student-1', alias: null);

    expect(student.counselorDisplayName(fullName: 'John Perera'), 'John Perera');
  });

  test('student with alias displays only the alias', () {
    const student = StudentModel(uid: 'student-1', alias: 'Student#4821');

    final label = student.counselorDisplayName(fullName: 'John Perera');

    expect(label, 'Student#4821');
    expect(label.contains('John Perera'), isFalse);
  });

  test('student search matches alias or full name case-insensitively', () {
    const student = StudentModel(uid: 'student-1', alias: 'Student#4821');

    expect(student.matchesCounselorSearch('john', fullName: 'John Perera'), isTrue);
    expect(student.matchesCounselorSearch('student#4821'), isTrue);
    expect(student.matchesCounselorSearch('john perera', fullName: 'John Perera'), isTrue);
  });

  test('legacy student documents default to normal priority', () {
    const student = StudentModel(uid: 'legacy-student');

    expect(student.priorityLevel, 'normal');
    expect(student.isHighPriority, isFalse);
  });
}
