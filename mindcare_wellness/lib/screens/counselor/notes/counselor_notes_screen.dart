import 'package:flutter/material.dart';

import '../../../models/session_note_model.dart';
import '../../../services/counselor_service.dart';
import '../../../services/session_note_service.dart';
import '../../../widgets/common/empty_state.dart';
import '../counselor_theme.dart';
import 'session_note_details_screen.dart';

class CounselorNotesScreen extends StatefulWidget {
  const CounselorNotesScreen({required this.service, super.key});

  final CounselorService service;

  @override
  State<CounselorNotesScreen> createState() => _CounselorNotesScreenState();
}

class _CounselorNotesScreenState extends State<CounselorNotesScreen> {
  final _noteService = SessionNoteService();
  Future<List<SessionNoteEntry>>? _entriesFuture;
  String _entryKey = '';

  Future<List<SessionNoteEntry>> _loadEntries(List<SessionNoteModel> notes) {
    final key = notes.map((note) => note.id).join('|');
    if (_entriesFuture == null || key != _entryKey) {
      _entryKey = key;
      _entriesFuture = _noteService.loadEntries(notes);
    }
    return _entriesFuture!;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: StreamBuilder<List<SessionNoteModel>>(
      stream: _noteService.forCounselor(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: dashboardGreen),
          );
        }
        if (snapshot.hasError) {
          return _NotesError(onRetry: () => setState(() {}));
        }
        final notes = snapshot.data ?? const <SessionNoteModel>[];
        return FutureBuilder<List<SessionNoteEntry>>(
          future: _loadEntries(notes),
          builder: (context, entrySnapshot) {
            if (entrySnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: dashboardGreen),
              );
            }
            if (entrySnapshot.hasError) {
              return _NotesError(onRetry: () => setState(() {}));
            }
            final allEntries = entrySnapshot.data ?? const [];

            // Group by student — one card per student, latest note first
            final groupedEntries = <String, List<SessionNoteEntry>>{};
            for (final entry in allEntries) {
              final key = entry.note.studentId.isNotEmpty
                  ? entry.note.studentId
                  : entry.studentLabel;
              groupedEntries.putIfAbsent(key, () => []).add(entry);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                const _NotesHeader(),
                const SizedBox(height: 20),
                if (notes.isEmpty)
                  const EmptyState(
                    message:
                        'No session notes yet\nCompleted counseling session notes will appear here.',
                  )
                else if (groupedEntries.isEmpty)
                  const EmptyState(message: 'No notes found.')
                else
                  ...groupedEntries.values.map(
                    (studentEntries) {
                      // Sort so latest session is first
                      final sorted = [...studentEntries]
                        ..sort((a, b) {
                          final dateA =
                              a.note.createdAt ?? a.appointment?.startAt;
                          final dateB =
                              b.note.createdAt ?? b.appointment?.startAt;
                          if (dateA == null && dateB == null) return 0;
                          if (dateA == null) return 1;
                          if (dateB == null) return -1;
                          return dateB.compareTo(dateA);
                        });
                      final latest = sorted.first;
                      final previous = sorted.skip(1).toList();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _StudentNoteCard(
                          latestEntry: latest,
                          previousEntries: previous,
                          totalCount: sorted.length,
                          onView: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SessionNoteDetailsScreen(
                                  entry: latest,
                                  previousEntries: previous,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        );
      },
    ),
  );
}

// ──────────────────────────────────────────
// Header (matches image top-bar style)
// ──────────────────────────────────────────
class _NotesHeader extends StatelessWidget {
  const _NotesHeader();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.shield_outlined, color: dashboardGreen, size: 22),
      ),
      const SizedBox(width: 12),
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
                letterSpacing: .7,
              ),
            ),
            Text(
              'Notes',
              style: TextStyle(
                color: dashboardInk,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD0EDD8), width: 1.5),
        ),
        child: const Icon(Icons.person, color: dashboardGreen, size: 22),
      ),
    ],
  );
}

// ──────────────────────────────────────────
// Student Note Card — one per student
// ──────────────────────────────────────────
class _StudentNoteCard extends StatelessWidget {
  const _StudentNoteCard({
    required this.latestEntry,
    required this.previousEntries,
    required this.totalCount,
    required this.onView,
  });

  final SessionNoteEntry latestEntry;
  final List<SessionNoteEntry> previousEntries;
  final int totalCount;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final appointment = latestEntry.appointment;
    final date = latestEntry.note.createdAt ?? appointment?.startAt;
    final noteText = latestEntry.note.note.trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Student identity row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF8E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: dashboardGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latestEntry.studentLabel,
                        style: const TextStyle(
                          color: dashboardInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '$totalCount ${totalCount == 1 ? 'session' : 'sessions'} logged',
                        style: const TextStyle(
                          color: dashboardGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── "LATEST CLINICAL SESSION" label ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD5F4DC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text(
                  'LATEST CLINICAL SESSION',
                  style: TextStyle(
                    color: dashboardGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: dashboardGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        color: Color(0xFF55F44C),
                        size: 7,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _sessionLabel(appointment?.sessionType),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Session meta ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: dashboardGreen,
                  size: 13,
                ),
                const SizedBox(width: 5),
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.access_time_outlined,
                  color: Colors.black38,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  _sessionLabel(appointment?.sessionType),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Note preview ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FBF3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFCCEDD4),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.edit_note_outlined,
                      color: dashboardGreen,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'SESSION NOTES',
                      style: TextStyle(
                        color: dashboardGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  noteText.isEmpty ? 'No note content.' : noteText,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: dashboardInk,
                    fontSize: 12,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── View button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.open_in_new, size: 15),
                label: const Text('View Full Clinical Record'),
                style: FilledButton.styleFrom(
                  backgroundColor: dashboardGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesError extends StatelessWidget {
  const _NotesError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, color: dashboardGreen, size: 42),
          const SizedBox(height: 12),
          const Text(
            'Unable to load session notes.',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            'Please check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

String _formatDate(DateTime? value) => value == null
    ? 'Date pending'
    : '${value.day} ${_months[value.month - 1]} ${value.year}';

String _sessionLabel(String? value) => switch (value) {
  'video' => 'Video consultation',
  'audio' => 'Audio session',
  'in_person' => 'In-person Review',
  'chat' => 'Chat session',
  _ => 'Counseling session',
};

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
