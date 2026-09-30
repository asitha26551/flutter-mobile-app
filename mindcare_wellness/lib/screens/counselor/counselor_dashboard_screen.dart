import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/counselor_models.dart';
import '../../services/auth_service.dart';
import '../../services/counselor_service.dart';
import '../../widgets/auth_widgets.dart';

const _dashboardGreen = Color(0xFF087A17);
const _dashboardBright = Color(0xFF55F44C);
const _dashboardMint = Color(0xFFE8FFF0);
const _dashboardInk = Color(0xFF0C2417);

class CounselorDashboardScreen extends StatefulWidget {
  const CounselorDashboardScreen({required this.authService, super.key});

  final AuthService authService;

  @override
  State<CounselorDashboardScreen> createState() => _CounselorDashboardScreenState();
}

class _CounselorDashboardScreenState extends State<CounselorDashboardScreen> {
  final service = CounselorService();
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _dashboardMint,
    body: IndexedStack(index: selectedIndex, children: [
      _Home(service: service),
      _CalendarScreen(service: service),
      _Messages(service: service),
      _Profile(service: service, authService: widget.authService),
    ]),
    bottomNavigationBar: NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => setState(() => selectedIndex = index),
      height: 70,
      backgroundColor: Colors.white,
      indicatorColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
        NavigationDestination(icon: Icon(Icons.sticky_note_2_outlined), selectedIcon: Icon(Icons.sticky_note_2), label: 'Notes'),
        NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
      ],
    ),
  );
}

class _Home extends StatelessWidget {
  const _Home({required this.service});
  final CounselorService service;

  @override
  Widget build(BuildContext context) => FutureBuilder<CounselorProfile>(
    future: service.getProfile(),
    builder: (context, profileSnapshot) {
      if (profileSnapshot.connectionState == ConnectionState.waiting) return const _Loading();
      if (profileSnapshot.hasError || profileSnapshot.data == null) return const _Error(message: 'We could not load your counselor dashboard.');
      final profile = profileSnapshot.data!;
      return StreamBuilder<List<CounselorAppointment>>(
        stream: service.appointments(),
        builder: (context, appointmentSnapshot) {
          final appointments = appointmentSnapshot.data ?? const <CounselorAppointment>[];
          final todayAppointments = _todayAppointments(appointments);
          return SafeArea(child: RefreshIndicator(
            onRefresh: service.getProfile,
            color: _dashboardGreen,
            child: ListView(padding: EdgeInsets.zero, children: [
              _PortalHeader(profile: profile),
              Padding(padding: const EdgeInsets.fromLTRB(17, 14, 17, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _DateLine(),
                const SizedBox(height: 5),
                Text('Hi, ${profile.name}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _dashboardInk)),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: _Stat(icon: Icons.event_available, value: todayAppointments.length, label: 'TODAY\nScheduled')),
                  const SizedBox(width: 8),
                  Expanded(child: _Stat(icon: Icons.event_busy_outlined, value: appointments.where((item) => item.status == 'rejected').length, label: 'NO-SHOW\nThis Week')),
                  const SizedBox(width: 8),
                  const Expanded(child: _Stat(icon: Icons.edit_note_outlined, value: 3, label: 'PENDING\nClinical Notes')),
                ]),
                const SizedBox(height: 25),
                const _SectionHeading('Upcoming Booking Today'),
                const SizedBox(height: 9),
                if (todayAppointments.isEmpty)
                  const _Empty(message: 'No appointments scheduled for today.')
                else ...[
                  _FeaturedAppointment(item: todayAppointments.first, service: service),
                  if (todayAppointments.length > 1) ...[
                    const SizedBox(height: 20),
                    const _SectionHeading('Remaining Bookings Today'),
                    const SizedBox(height: 9),
                    ...todayAppointments.skip(1).map((item) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _CompactAppointment(item: item))),
                  ],
                ],
              ])),
            ]),
          ));
        },
      );
    },
  );
}

List<CounselorAppointment> _todayAppointments(List<CounselorAppointment> appointments) {
  final now = DateTime.now();
  return appointments.where((item) {
    final date = item.startAt;
    return date != null && date.year == now.year && date.month == now.month && date.day == now.day && (item.status == 'pending' || item.status == 'confirmed');
  }).toList()..sort((a, b) => (a.startAt ?? DateTime(2100)).compareTo(b.startAt ?? DateTime(2100)));
}

class _PortalHeader extends StatelessWidget {
  const _PortalHeader({required this.profile});
  final CounselorProfile profile;

  @override
  Widget build(BuildContext context) => Container(
    color: _dashboardMint,
    padding: const EdgeInsets.fromLTRB(21, 13, 17, 12),
    child: Row(children: [
      Container(width: 30, height: 30, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.shield_outlined, color: _dashboardGreen, size: 19)),
      const SizedBox(width: 10),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('COUNSELOR PORTAL', style: TextStyle(color: _dashboardGreen, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .6)), Text('Home', style: TextStyle(color: _dashboardInk, fontSize: 17, fontWeight: FontWeight.w800))])),
      Stack(children: [CircleAvatar(radius: 20, backgroundColor: mintGreen, backgroundImage: profile.imageUrl == null ? null : NetworkImage(profile.imageUrl!), child: profile.imageUrl == null ? const Icon(Icons.person, color: _dashboardGreen) : null), Positioned(right: 0, bottom: 0, child: Container(width: 9, height: 9, decoration: BoxDecoration(color: _dashboardBright, shape: BoxShape.circle, border: Border.all(color: _dashboardMint, width: 2))))]),
    ]),
  );
}

class _DateLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) { final now = DateTime.now(); return Row(children: [const Icon(Icons.calendar_today_outlined, size: 12, color: _dashboardGreen), const SizedBox(width: 5), Text('${_weekday(now.weekday)}, ${now.day} ${_month(now.month)} ${now.year}', style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .4))]); }
}

String _weekday(int day) => const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][day - 1].toUpperCase();
String _month(int month) => const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][month - 1].toUpperCase();

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon; final int value; final String label;
  @override
  Widget build(BuildContext context) => Container(height: 91, padding: const EdgeInsets.symmetric(vertical: 9), decoration: BoxDecoration(color: const Color(0xFFDFF9E8), borderRadius: BorderRadius.circular(12)), child: Column(children: [Container(width: 27, height: 27, decoration: const BoxDecoration(color: Color(0xFFC9F2D5), shape: BoxShape.circle), child: Icon(icon, size: 15, color: _dashboardGreen)), const SizedBox(height: 2), Text('$value', style: const TextStyle(color: _dashboardInk, fontSize: 17, fontWeight: FontWeight.w900)), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 9, height: 1.05, fontWeight: FontWeight.w600))]));
}

class _SectionHeading extends StatelessWidget { const _SectionHeading(this.text); final String text; @override Widget build(BuildContext context) => Row(children: [const Icon(Icons.access_time, size: 16, color: _dashboardGreen), const SizedBox(width: 5), Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _dashboardInk))]); }

class _FeaturedAppointment extends StatelessWidget {
  const _FeaturedAppointment({required this.item, required this.service});
  final CounselorAppointment item; final CounselorService service;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(14, 12, 14, 13), decoration: BoxDecoration(color: _dashboardGreen, borderRadius: BorderRadius.circular(11), boxShadow: const [BoxShadow(color: Color(0x33087517), blurRadius: 12, offset: Offset(0, 6))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: _Tag(icon: Icons.circle, text: 'In-Person · ${_time(item.startAt)}', color: _dashboardBright)), const SizedBox(width: 6), _Tag(text: 'HIGH PRIORITY', color: Colors.red.shade700)]), const SizedBox(height: 9), Row(children: [Expanded(child: Text(item.studentId.isEmpty ? 'Student appointment' : 'Student #${_shortId(item.studentId)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))), _SoftTag(text: item.sessionType)]), const SizedBox(height: 2), const Text('Undergraduate · Year 2 · Science Faculty', style: TextStyle(color: Colors.white70, fontSize: 11)), const SizedBox(height: 10), Row(children: [Expanded(child: _SoftTag(text: '😊 Smiling Check-in')), const SizedBox(width: 5), const Expanded(child: _SoftTag(text: '▣ Focus: Academic Stress &\n   Midterm Fatigue'))]), const SizedBox(height: 7), const _DetailLine(icon: Icons.location_on_outlined, text: 'Room 204 · Mental Health Wing'), const SizedBox(height: 11), SizedBox(width: double.infinity, height: 40, child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.meeting_room_outlined, size: 16), label: const Text('Open Session Workspace'), style: FilledButton.styleFrom(backgroundColor: _dashboardBright, foregroundColor: _dashboardInk, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))), const SizedBox(height: 7), SizedBox(width: double.infinity, height: 38, child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.note_add_outlined, size: 16), label: const Text('Quick Review Notes'), style: FilledButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))), if (item.status == 'pending') Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => service.updateAppointment(item.id, 'confirmed'), child: const Text('Accept request', style: TextStyle(color: Colors.white))))]));
}

class _CompactAppointment extends StatelessWidget {
  const _CompactAppointment({required this.item}); final CounselorAppointment item;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(14, 11, 14, 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text('${_time(item.startAt)}  ·  ${item.sessionType}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))), _Pill(item.status)]), const SizedBox(height: 7), Text(item.studentId.isEmpty ? 'Student appointment' : 'Student #${_shortId(item.studentId)}', style: const TextStyle(color: _dashboardInk, fontWeight: FontWeight.w800, fontSize: 14)), const SizedBox(height: 2), Text(item.sessionType, style: const TextStyle(color: Colors.black54, fontSize: 11)), const SizedBox(height: 7), const Row(children: [Expanded(child: _SoftTag(text: 'Smiling Check-in', light: true)), SizedBox(width: 5), Expanded(child: _SoftTag(text: 'Encrypted Audio Session', light: true))])]));
}

class _Tag extends StatelessWidget { const _Tag({this.icon, required this.text, required this.color}); final IconData? icon; final String text; final Color color; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) Icon(icon, size: 8, color: _dashboardInk), if (icon != null) const SizedBox(width: 4), Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _dashboardInk))])); }
class _SoftTag extends StatelessWidget { const _SoftTag({required this.text, this.light = false}); final String text; final bool light; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5), decoration: BoxDecoration(color: light ? const Color(0xFFDDF5E5) : Colors.white24, borderRadius: BorderRadius.circular(10)), child: Text(text, style: TextStyle(color: light ? _dashboardGreen : Colors.white, fontSize: 9, height: 1.1))); }
class _DetailLine extends StatelessWidget { const _DetailLine({required this.icon, required this.text}); final IconData icon; final String text; @override Widget build(BuildContext context) => Row(children: [Icon(icon, color: Colors.white, size: 14), const SizedBox(width: 5), Text(text, style: const TextStyle(color: Colors.white, fontSize: 10))]); }
class _Pill extends StatelessWidget { const _Pill(this.status); final String status; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: _dashboardBright, borderRadius: BorderRadius.circular(12)), child: Text(status.toUpperCase(), style: const TextStyle(color: _dashboardInk, fontSize: 8, fontWeight: FontWeight.w800))); }
String _shortId(String value) => value.length > 6 ? value.substring(0, 6) : value;
String _time(DateTime? date) => date == null ? 'Time TBD' : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

class _Appointments extends StatelessWidget { const _Appointments({required this.service}); final CounselorService service; @override Widget build(BuildContext context) => SafeArea(child: StreamBuilder<List<CounselorAppointment>>(stream: service.appointments(), builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) return const _Loading(); if (snapshot.hasError) return const _Error(message: 'Appointments are unavailable right now.'); final items = snapshot.data ?? const <CounselorAppointment>[]; return ListView(padding: const EdgeInsets.all(17), children: [Text('Calendar', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 5), const Text('Manage your counseling bookings.', style: TextStyle(color: Colors.black54)), const SizedBox(height: 18), if (items.isEmpty) const _Empty(message: 'No appointments yet.') else ...items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _CompactAppointment(item: item)))]); })); }
class _Messages extends StatelessWidget { const _Messages({required this.service}); final CounselorService service; @override Widget build(BuildContext context) => SafeArea(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: service.conversations(), builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) return const _Loading(); if (snapshot.hasError) return const _Error(message: 'Messages are unavailable right now.'); final docs = snapshot.data?.docs ?? []; return ListView(padding: const EdgeInsets.all(17), children: [Text('Notes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 5), const Text('Keep in touch with your students.', style: TextStyle(color: Colors.black54)), const SizedBox(height: 18), if (docs.isEmpty) const _Empty(message: 'No conversations yet.') else ...docs.map((doc) => Card(child: ListTile(leading: const CircleAvatar(backgroundColor: mintGreen, child: Icon(Icons.person, color: _dashboardGreen)), title: Text(doc.data()['studentName'] as String? ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(doc.data()['lastMessage'] as String? ?? 'No messages yet'), trailing: const Icon(Icons.chevron_right))))]); })); }
class _Profile extends StatelessWidget { const _Profile({required this.service, required this.authService}); final CounselorService service; final AuthService authService; @override Widget build(BuildContext context) => FutureBuilder<CounselorProfile>(future: service.getProfile(), builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) return const _Loading(); if (snapshot.hasError || snapshot.data == null) return const _Error(message: 'Profile is unavailable right now.'); final profile = snapshot.data!; return SafeArea(child: ListView(padding: const EdgeInsets.all(17), children: [Text('Profile', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 18), Card(child: ListTile(leading: CircleAvatar(backgroundColor: mintGreen, backgroundImage: profile.imageUrl == null ? null : NetworkImage(profile.imageUrl!), child: profile.imageUrl == null ? const Icon(Icons.person, color: _dashboardGreen) : null), title: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${profile.professionalRole}\n${profile.department}'))), const SizedBox(height: 10), Card(child: Column(children: [ListTile(leading: const Icon(Icons.email_outlined), title: Text(profile.user['email'] as String? ?? 'Email')), ListTile(leading: const Icon(Icons.phone_outlined), title: Text(profile.user['phoneNumber'] as String? ?? 'Phone not added'))])), const SizedBox(height: 18), OutlinedButton.icon(onPressed: authService.logout, icon: const Icon(Icons.logout), label: const Text('Log out'))])); }); }
class _Empty extends StatelessWidget { const _Empty({required this.message}); final String message; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(22), child: Center(child: Text(message, style: const TextStyle(color: Colors.black54))))); }
class _Loading extends StatelessWidget { const _Loading(); @override Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: _dashboardGreen)); }
class _Error extends StatelessWidget { const _Error({required this.message}); final String message; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center))); }

class _CalendarScreen extends StatelessWidget {
  const _CalendarScreen({required this.service});
  final CounselorService service;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: StreamBuilder<List<CounselorAppointment>>(
      stream: service.appointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const _Loading();
        if (snapshot.hasError) return const _Error(message: 'Appointments are unavailable right now.');
        final appointments = snapshot.data ?? const <CounselorAppointment>[];
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const _CalendarHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 12, 15, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _MonthCard(),
                  const SizedBox(height: 15),
                  const Text('Tue 15', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const Text('Time Slots (5 Total)', style: TextStyle(color: Colors.black54, fontSize: 9)),
                  const SizedBox(height: 9),
                  if (appointments.isEmpty) ...const [
                    _CalendarBooking(time: '09:30 - 10:15', student: 'Student #4821', topic: 'Academic Stress & Midterm Fatigue', tag: 'In-Person', status: 'HIGH PRIORITY', color: _dashboardGreen, action: 'View →'),
                    _CalendarBooking(time: '10:15 - 11:00', student: 'Student #1190', topic: 'Anxiety about study performance', tag: 'Voice Call', status: 'Live Next', color: _dashboardGreen, action: 'Join →'),
                    _CalendarBooking(time: '11:00 - 11:45', student: 'Student #7734', topic: 'General Routine Check-in', tag: 'In-Person Room 2B', status: 'Missed Check-in', color: Colors.orange, action: 'Dispatch Follow-up'),
                  ] else ...appointments.take(5).map((item) => _DataCalendarBooking(item: item)),
                  const _OpenSlot(),
                  const _LunchBreak(),
                  const _CalendarBooking(time: '13:30 - 14:15', student: 'Student #0552', topic: 'Sleep Hygiene & Exhaustion concerns', tag: 'Encrypted Chat', status: 'Upcoming', color: _dashboardGreen, action: 'Prepare Chat'),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader();

  @override
  Widget build(BuildContext context) => Container(
    color: _dashboardMint,
    padding: const EdgeInsets.fromLTRB(18, 12, 17, 13),
    child: Row(children: [
      Container(width: 29, height: 29, decoration: BoxDecoration(color: const Color(0xFFD5F8DF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.calendar_month_outlined, color: _dashboardGreen, size: 18)),
      const SizedBox(width: 10),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('COUNSELOR PORTAL', style: TextStyle(color: _dashboardGreen, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .5)), Text('Calendar', style: TextStyle(color: _dashboardInk, fontSize: 17, fontWeight: FontWeight.w800))])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFD6F8DE), borderRadius: BorderRadius.circular(12)), child: const Text('Synced just now', style: TextStyle(color: _dashboardGreen, fontSize: 8, fontWeight: FontWeight.w700))),
      const SizedBox(width: 8),
      const CircleAvatar(radius: 18, backgroundColor: mintGreen, child: Icon(Icons.person, color: _dashboardGreen)),
    ]),
  );
}

class _MonthCard extends StatelessWidget {
  const _MonthCard();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final offset = firstDay.weekday % 7;
    final days = DateTime(now.year, now.month + 1, 0).day;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
      child: Column(children: [
        Row(children: [const Icon(Icons.chevron_left, color: Colors.blueGrey, size: 18), const Spacer(), Text('${_month(now.month)} ${now.year}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)), const Spacer(), const Icon(Icons.chevron_right, color: Colors.blueGrey, size: 18)]),
        const SizedBox(height: 10),
        const Row(children: [
          Expanded(child: Center(child: Text('S', style: TextStyle(color: Colors.blueGrey, fontSize: 8)))),
          Expanded(child: Center(child: Text('M', style: TextStyle(color: Colors.blueGrey, fontSize: 8)))),
          Expanded(child: Center(child: Text('T', style: TextStyle(color: Colors.blueGrey, fontSize: 8)))),
          Expanded(child: Center(child: Text('W', style: TextStyle(color: Colors.blueGrey, fontSize: 8)))),
          Expanded(child: Center(child: Text('T', style: TextStyle(color: Colors.blueGrey, fontSize: 8)))),
          Expanded(child: Center(child: Text('F', style: TextStyle(color: Colors.blueGrey, fontSize: 8)))),
          Expanded(child: Center(child: Text('S', style: TextStyle(color: Colors.blueGrey, fontSize: 8)))),
        ]),
        const SizedBox(height: 5),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: 22),
          itemBuilder: (context, index) {
            final number = index - offset + 1;
            if (number < 1 || number > days) return const SizedBox();
            final selected = number == now.day;
            return Center(child: Container(width: 17, height: 17, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? _dashboardGreen : Colors.transparent, shape: BoxShape.circle), child: Text('$number', style: TextStyle(color: selected ? Colors.white : _dashboardInk, fontSize: 8, fontWeight: selected ? FontWeight.w800 : FontWeight.w400))));
          },
        ),
      ]),
    );
  }
}

class _CalendarBooking extends StatelessWidget {
  const _CalendarBooking({required this.time, required this.student, required this.topic, required this.tag, required this.status, required this.color, required this.action});
  final String time;
  final String student;
  final String topic;
  final String tag;
  final String status;
  final Color color;
  final String action;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: color, width: 3))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(time, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800))), _CalendarStatus(text: status, urgent: status == 'HIGH PRIORITY')]),
      const SizedBox(height: 6),
      Text(student, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      Text('Topic: $topic', style: const TextStyle(color: Colors.blueGrey, fontSize: 8)),
      const SizedBox(height: 7),
      Row(children: [Expanded(child: _CalendarChip(text: tag)), const SizedBox(width: 5), Container(height: 22, padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.center, decoration: BoxDecoration(color: _dashboardGreen, borderRadius: BorderRadius.circular(6)), child: Text(action, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)))])
    ]),
  );
}

class _DataCalendarBooking extends StatelessWidget {
  const _DataCalendarBooking({required this.item});
  final CounselorAppointment item;
  @override
  Widget build(BuildContext context) => _CalendarBooking(time: _time(item.startAt), student: item.studentId.isEmpty ? 'Student appointment' : 'Student #${_shortId(item.studentId)}', topic: item.sessionType, tag: item.sessionType, status: item.status == 'confirmed' ? 'Upcoming' : 'PENDING', color: item.status == 'confirmed' ? _dashboardGreen : Colors.orange, action: item.status == 'pending' ? 'Review →' : 'View →');
}

class _CalendarStatus extends StatelessWidget { const _CalendarStatus({required this.text, this.urgent = false}); final String text; final bool urgent; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: urgent ? Colors.red.shade700 : const Color(0xFFD9F7E1), borderRadius: BorderRadius.circular(6)), child: Text(text, style: TextStyle(color: urgent ? Colors.white : _dashboardGreen, fontSize: 7, fontWeight: FontWeight.w800))); }
class _CalendarChip extends StatelessWidget { const _CalendarChip({required this.text}); final String text; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE1F7E8), borderRadius: BorderRadius.circular(5)), child: Text(text, style: const TextStyle(color: _dashboardGreen, fontSize: 7, fontWeight: FontWeight.w600))); }
class _OpenSlot extends StatelessWidget { const _OpenSlot(); @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9), decoration: BoxDecoration(color: const Color(0xFFD9F9E4), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.add_circle_outline, color: Color(0xFF72D994), size: 17), const SizedBox(width: 8), const Expanded(child: Text('11:45 - 12:30\nUnallocated Slot', style: TextStyle(fontSize: 9, height: 1.35))), OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: _dashboardGreen, side: const BorderSide(color: _dashboardGreen), minimumSize: const Size(52, 25), padding: EdgeInsets.zero), child: const Text('+ Book', style: TextStyle(fontSize: 8))) ])); }
class _LunchBreak extends StatelessWidget { const _LunchBreak(); @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9), decoration: BoxDecoration(color: const Color(0xFFF1F6F3), borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.schedule, color: Colors.blueGrey, size: 14), SizedBox(width: 8), Text('12:30 - 13:30   Lunch Break', style: TextStyle(color: Colors.blueGrey, fontSize: 9))])); }