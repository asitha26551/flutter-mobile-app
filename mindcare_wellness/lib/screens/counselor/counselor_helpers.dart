import '../../models/counselor_models.dart';

List<CounselorAppointment> todayAppointments(
  List<CounselorAppointment> appointments,
) {
  final now = DateTime.now();
  return appointments.where((item) {
    final date = item.startAt;
    return date != null &&
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day &&
        (item.status == 'pending' || item.status == 'confirmed');
  }).toList()..sort(
    (a, b) =>
        (a.startAt ?? DateTime(2100)).compareTo(b.startAt ?? DateTime(2100)),
  );
}

String shortStudentId(String value) =>
    value.length > 6 ? value.substring(0, 6) : value;

String appointmentTime(DateTime? date) => date == null
    ? 'Time TBD'
    : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String weekdayName(int day) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][day - 1].toUpperCase();

String monthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1].toUpperCase();
