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
        (item.status == 'pending' || item.status == 'confirmed' || item.status == 'rescheduled');
  }).toList()..sort(
    (a, b) =>
        (a.startAt ?? DateTime(2100)).compareTo(b.startAt ?? DateTime(2100)),
  );
}

String shortStudentId(String value) =>
    value.length > 6 ? value.substring(0, 6) : value;

String appointmentTime(DateTime? date) => date == null
    ? 'Time TBD'
    : '${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour < 12 ? 'AM' : 'PM'}';

String appointmentRange(CounselorAppointment item) {
  final start = appointmentTime(item.startAt);
  final end = item.endAt;
  return end == null ? start : '$start - ${appointmentTime(end)}';
}

String appointmentStatusLabel(String status) => switch (status) {
  'no_show' => 'No show',
  'confirmed' => 'Confirmed',
  'pending' => 'Pending',
  'cancelled' => 'Cancelled',
  'completed' => 'Completed',
  'rejected' => 'Rejected',
  'rescheduled' => 'Rescheduled',
  _ => status.replaceAll('_', ' '),
};

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
