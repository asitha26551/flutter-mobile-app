import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/counselor_service.dart';
import '../../../widgets/auth_widgets.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/error_message.dart';
import '../../../widgets/common/loading.dart';
import '../counselor_theme.dart';

class CounselorNotesScreen extends StatelessWidget {
  const CounselorNotesScreen({required this.service, super.key});
  final CounselorService service;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.conversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LoadingWidget();
        if (snapshot.hasError)
          return const ErrorMessage(
            message: 'Notes are unavailable right now.',
          );
        final docs = snapshot.data?.docs ?? [];
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const _NotesHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SearchField(),
                  const SizedBox(height: 14),
                  const _Filters(),
                  const SizedBox(height: 15),
                  if (docs.isEmpty)
                    const EmptyState(message: 'No conversations yet.')
                  else
                    ...docs.map((doc) => _NoteCard(data: doc.data())),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _NotesHeader extends StatelessWidget {
  const _NotesHeader();
  @override
  Widget build(BuildContext context) => Container(
    color: dashboardMint,
    padding: const EdgeInsets.fromLTRB(18, 12, 17, 13),
    child: Row(
      children: [
        Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            color: const Color(0xFFD5F8DF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: dashboardGreen,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COUNSELOR PORTAL',
                style: TextStyle(
                  color: dashboardGreen,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
              Text(
                'Notes',
                style: TextStyle(
                  color: dashboardInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const CircleAvatar(
          radius: 18,
          backgroundColor: mintGreen,
          child: Icon(Icons.person, color: dashboardGreen),
        ),
      ],
    ),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: TextField(
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, size: 17, color: dashboardGreen),
        hintText: 'Search student alias... (e.g. Student#4821)',
        hintStyle: const TextStyle(color: Color(0xFF7DAF91), fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF8AE4A8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dashboardGreen),
        ),
      ),
    ),
  );
}

class _Filters extends StatelessWidget {
  const _Filters();
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: const [
        _FilterChip(text: 'All (4)', selected: true),
        SizedBox(width: 8),
        _FilterChip(text: 'Needs follow-up (1)'),
        SizedBox(width: 8),
        _FilterChip(text: 'Recent'),
        SizedBox(width: 8),
        _FilterChip(text: 'High priority'),
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.text, this.selected = false});
  final String text;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: selected ? dashboardGreen : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: selected ? dashboardGreen : const Color(0xFF9BDEB0),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selected) const Icon(Icons.circle, size: 7, color: dashboardBright),
        if (selected) const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : dashboardInk,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final student =
        data['studentName'] as String? ??
        data['studentAlias'] as String? ??
        'Student';
    final message =
        data['lastMessage'] as String? ?? 'No note summary available';
    final priority = data['priority'] as String?;
    final mood = data['mood'] as String? ?? 'Neutral mood';
    final followUp = priority == 'high' || data['needsFollowUp'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: followUp
            ? const Border(left: BorderSide(color: Colors.redAccent, width: 4))
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x12087517),
            blurRadius: 9,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: followUp
                      ? const Color(0xFFFFEEF0)
                      : const Color(0xFFE5FAEB),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  followUp ? Icons.flag_outlined : Icons.person_outline,
                  size: 16,
                  color: followUp ? Colors.redAccent : dashboardGreen,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student,
                      style: const TextStyle(
                        color: dashboardInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      data['sessionSummary'] as String? ??
                          '2 sessions • Last interaction recent',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              _MoodBadge(text: mood, followUp: followUp),
            ],
          ),
          const SizedBox(height: 11),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: followUp
                  ? const Color(0xFFFFFCF0)
                  : const Color(0xFFEAF9EF),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: followUp
                    ? const Color(0xFFFFE09A)
                    : const Color(0xFFD2F1DC),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  followUp ? 'TOPIC / CONCERN' : 'PRIMARY CONCERN',
                  style: TextStyle(
                    color: followUp ? dashboardInk : dashboardGreen,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: dashboardInk,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: followUp ? Colors.redAccent : Colors.blueGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      data['lastMessageTime'] as String? ?? 'Today, 09:30 AM',
                      style: TextStyle(
                        color: followUp ? Colors.redAccent : Colors.blueGrey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 27,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dashboardGreen,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  'View  ›',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodBadge extends StatelessWidget {
  const _MoodBadge({required this.text, required this.followUp});
  final String text;
  final bool followUp;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: followUp ? const Color(0xFFFFEEF0) : const Color(0xFFE8FFF0),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: followUp ? const Color(0xFFFFB6BE) : const Color(0xFF9CE8B2),
      ),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: followUp ? Colors.redAccent : dashboardGreen,
        fontSize: 8,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
