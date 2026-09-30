import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/counselor_models.dart';
import '../../services/auth_service.dart';
import '../../services/counselor_service.dart';
import '../../widgets/auth_widgets.dart';

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
    backgroundColor: pageBackground,
    body: IndexedStack(index: selectedIndex, children: [
      _Home(service: service),
      _Appointments(service: service),
      _Messages(service: service),
      _Profile(service: service, authService: widget.authService),
    ]),
    bottomNavigationBar: NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => setState(() => selectedIndex = index),
      backgroundColor: Colors.white,
      indicatorColor: mintGreen,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Appointments'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Messages'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
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
          final today = DateTime.now();
          final todayAppointments = appointments.where((appointment) {
            final date = appointment.startAt;
            return date != null && date.year == today.year && date.month == today.month && date.day == today.day && (appointment.status == 'pending' || appointment.status == 'confirmed');
          }).toList();
          return SafeArea(child: RefreshIndicator(onRefresh: service.getProfile, child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
            _Header(profile: profile),
            const SizedBox(height: 16),
            _ProfileCard(profile: profile),
            const SizedBox(height: 22),
            const _Title('Today\'s Overview'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _Stat(icon: Icons.event_available, value: todayAppointments.length, label: 'Today\'s\nAppointments')),
              const SizedBox(width: 10),
              Expanded(child: _Stat(icon: Icons.pending_actions, value: appointments.where((item) => item.status == 'pending').length, label: 'Pending\nRequests')),
              const SizedBox(width: 10),
              const Expanded(child: _Stat(icon: Icons.chat_bubble_outline, value: 0, label: 'Unread\nMessages')),
            ]),
            const SizedBox(height: 22),
            const _Title('Upcoming Booking Today'),
            const SizedBox(height: 10),
            if (todayAppointments.isEmpty) const _Empty(message: 'No appointments scheduled for today.') else ...todayAppointments.take(3).map((item) => _Appointment(item: item, service: service)),
            const SizedBox(height: 12),
            const _Title('Quick Actions'),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: _Quick(icon: Icons.calendar_month, label: 'Calendar')), const SizedBox(width: 10), Expanded(child: _Quick(icon: Icons.chat_bubble_outline, label: 'Messages'))]),
          ])));
        },
      );
    },
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});
  final CounselorProfile profile;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('COUNSELOR PORTAL', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: primaryGreen, fontWeight: FontWeight.w800, letterSpacing: .8)), Text('Good morning, ${profile.name}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const Text('Here\'s your counseling overview for today.', style: TextStyle(color: Colors.black54))])),
    CircleAvatar(radius: 23, backgroundColor: mintGreen, backgroundImage: profile.imageUrl == null ? null : NetworkImage(profile.imageUrl!), child: profile.imageUrl == null ? const Icon(Icons.person, color: primaryGreen) : null),
  ]);
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});
  final CounselorProfile profile;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [CircleAvatar(radius: 30, backgroundColor: mintGreen, backgroundImage: profile.imageUrl == null ? null : NetworkImage(profile.imageUrl!), child: profile.imageUrl == null ? const Icon(Icons.person, color: primaryGreen, size: 30) : null), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(profile.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 3), Text(profile.professionalRole, style: const TextStyle(color: Colors.black54)), Text(profile.department, style: const TextStyle(color: Colors.black54, fontSize: 12)), const SizedBox(height: 7), const Row(children: [Icon(Icons.verified, size: 16, color: primaryGreen), SizedBox(width: 5), Text('Verified', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700))])]))])));
}

class _Title extends StatelessWidget { const _Title(this.text); final String text; @override Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)); }
class _Stat extends StatelessWidget { const _Stat({required this.icon, required this.value, required this.label}); final IconData icon; final int value; final String label; @override Widget build(BuildContext context) => Card(color: mintGreen, child: Padding(padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8), child: Column(children: [Icon(icon, color: primaryGreen, size: 21), const SizedBox(height: 4), Text('$value', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: primaryGreen)), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, height: 1.1))]))); }
class _Quick extends StatelessWidget { const _Quick({required this.icon, required this.label}); final IconData icon; final String label; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Icon(icon, color: primaryGreen), const SizedBox(width: 9), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))]))); }
class _Empty extends StatelessWidget { const _Empty({required this.message}); final String message; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(22), child: Center(child: Text(message, style: const TextStyle(color: Colors.black54))))); }
class _Loading extends StatelessWidget { const _Loading(); @override Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: primaryGreen)); }
class _Error extends StatelessWidget { const _Error({required this.message}); final String message; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center))); }

class _Appointment extends StatelessWidget {
  const _Appointment({required this.item, required this.service});
  final CounselorAppointment item;
  final CounselorService service;
  @override
  Widget build(BuildContext context) { final start = item.startAt; return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(item.studentId.isEmpty ? 'Student appointment' : 'Student #${item.studentId.substring(0, item.studentId.length > 6 ? 6 : item.studentId.length)}', style: const TextStyle(fontWeight: FontWeight.w800))), _Pill(item.status)]), const SizedBox(height: 5), Text('${_time(start)}  ·  ${item.sessionType}', style: const TextStyle(color: Colors.black54)), if (item.status == 'pending') Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => service.updateAppointment(item.id, 'rejected'), child: const Text('Reject')), FilledButton(onPressed: () => service.updateAppointment(item.id, 'confirmed'), child: const Text('Accept'))])]))); }
}

String _time(DateTime? date) => date == null ? 'Time to be confirmed' : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
class _Pill extends StatelessWidget { const _Pill(this.status); final String status; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: status == 'confirmed' ? mintGreen : Colors.amber.shade100, borderRadius: BorderRadius.circular(20)), child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: status == 'confirmed' ? primaryGreen : Colors.brown, fontWeight: FontWeight.w800))); }

class _Appointments extends StatelessWidget {
  const _Appointments({required this.service}); final CounselorService service;
  @override
  Widget build(BuildContext context) => SafeArea(child: StreamBuilder<List<CounselorAppointment>>(stream: service.appointments(), builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) return const _Loading(); if (snapshot.hasError) return const _Error(message: 'Appointments are unavailable right now.'); final items = snapshot.data ?? const <CounselorAppointment>[]; return ListView(padding: const EdgeInsets.all(16), children: [Text('Calendar', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 4), const Text('Manage your counseling bookings.', style: TextStyle(color: Colors.black54)), const SizedBox(height: 18), if (items.isEmpty) const _Empty(message: 'No appointments yet.') else ...items.map((item) => _Appointment(item: item, service: service))]); }));
}

class _Messages extends StatelessWidget {
  const _Messages({required this.service}); final CounselorService service;
  @override
  Widget build(BuildContext context) => SafeArea(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: service.conversations(), builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) return const _Loading(); if (snapshot.hasError) return const _Error(message: 'Messages are unavailable right now.'); final docs = snapshot.data?.docs ?? []; return ListView(padding: const EdgeInsets.all(16), children: [Text('Messages', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 4), const Text('Keep in touch with your students.', style: TextStyle(color: Colors.black54)), const SizedBox(height: 18), if (docs.isEmpty) const _Empty(message: 'No conversations yet.') else ...docs.map((doc) => Card(child: ListTile(leading: const CircleAvatar(backgroundColor: mintGreen, child: Icon(Icons.person, color: primaryGreen)), title: Text(doc.data()['studentName'] as String? ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(doc.data()['lastMessage'] as String? ?? 'No messages yet'), trailing: const Icon(Icons.chevron_right))))]); }));
}

class _Profile extends StatelessWidget {
  const _Profile({required this.service, required this.authService}); final CounselorService service; final AuthService authService;
  @override
  Widget build(BuildContext context) => FutureBuilder<CounselorProfile>(future: service.getProfile(), builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) return const _Loading(); if (snapshot.hasError || snapshot.data == null) return const _Error(message: 'Profile is unavailable right now.'); final profile = snapshot.data!; return SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [Text('Profile', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 18), _ProfileCard(profile: profile), const SizedBox(height: 12), Card(child: Column(children: [ListTile(leading: const Icon(Icons.email_outlined), title: Text(profile.user['email'] as String? ?? 'Email')), ListTile(leading: const Icon(Icons.phone_outlined), title: Text(profile.user['phoneNumber'] as String? ?? 'Phone not added')), ListTile(leading: const Icon(Icons.business_outlined), title: Text(profile.department))])), const SizedBox(height: 18), OutlinedButton.icon(onPressed: authService.logout, icon: const Icon(Icons.logout), label: const Text('Log out'))])); });
}