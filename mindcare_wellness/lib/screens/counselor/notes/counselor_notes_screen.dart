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
  final _searchController = TextEditingController();
  Future<List<SessionNoteEntry>>? _entriesFuture;
  String _entryKey = '';
  String _filter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SessionNoteEntry> _filterEntries(List<SessionNoteEntry> entries) {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    return entries.where((entry) {
      final created = entry.note.createdAt;
      final recent = created != null && now.difference(created).inDays <= 30;
      final searchable = [
        entry.studentLabel,
        entry.note.note,
        entry.appointment?.reason ?? '',
        entry.appointment?.sessionType ?? '',
      ].join(' ').toLowerCase();
      final matchesFilter =
          _filter == 'All' ||
          (_filter == 'Recent' && recent) ||
          (_filter == 'Previous Sessions' && !recent);
      return matchesFilter && (query.isEmpty || searchable.contains(query));
    }).toList();
  }

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
            final entries = _filterEntries(entrySnapshot.data ?? const []);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                const _NotesHeader(),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search notes or students',
                    prefixIcon: const Icon(Icons.search, color: dashboardGreen),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                _FilterBar(
                  selected: _filter,
                  onSelected: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: 16),
                if (notes.isEmpty)
                  const EmptyState(
                    message: 'No session notes yet\nCompleted counseling session notes will appear here.',
                  )
                else if (entries.isEmpty)
                  const EmptyState(message: 'No notes match your search.')
                else
                  ...entries.map(
                    (entry) => _NoteRow(
                      entry: entry,
                      onView: () {
                        final previousEntries = entrySnapshot.data!
                            .where(
                              (candidate) =>
                                  candidate.note.studentId ==
                                      entry.note.studentId &&
                                  candidate.note.id != entry.note.id,
                            )
                            .toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SessionNoteDetailsScreen(
                              entry: entry,
                              previousEntries: previousEntries,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    ),
  );
}

class _NotesHeader extends StatelessWidget {
  const _NotesHeader();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(
            Icons.sticky_note_2_outlined,
            color: dashboardGreen,
            size: 28,
          ),
          const SizedBox(width: 10),
          Text(
            'Notes',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: dashboardInk, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      const SizedBox(height: 5),
      const Text(
        'Review your previous counseling sessions and session notes.',
        style: TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 9),
      const Row(
        children: [
          Icon(Icons.lock_outline, color: dashboardGreen, size: 15),
          SizedBox(width: 5),
          Text(
            'Private counselor notes',
            style: TextStyle(
              color: dashboardGreen,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ],
  );
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: ['All', 'Recent', 'Previous Sessions']
          .map(
            (filter) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter),
                selected: selected == filter,
                onSelected: (_) => onSelected(filter),
                selectedColor: dashboardGreen,
                labelStyle: TextStyle(
                  color: selected == filter ? Colors.white : dashboardInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.entry, required this.onView});

  final SessionNoteEntry entry;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final appointment = entry.appointment;
    final date = entry.note.createdAt ?? appointment?.startAt;
    final preview = entry.note.note.replaceAll(RegExp(r'\s+'), ' ').trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.studentLabel,
                    style: const TextStyle(
                      color: dashboardInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  _sessionType(appointment?.sessionType),
                  style: const TextStyle(
                    color: dashboardGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text('  •  ', style: TextStyle(color: Colors.black38)),
                const Text(
                  'Completed',
                  style: TextStyle(
                    color: dashboardGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              preview.isEmpty ? 'No note preview available.' : preview,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: dashboardInk, height: 1.35),
            ),
            const SizedBox(height: 11),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  backgroundColor: dashboardGreen,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
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

String _sessionType(String? value) => switch (value) {
  'video' => 'Video',
  'audio' => 'Audio',
  'in_person' => 'In-person',
  'chat' => 'Chat',
  _ => 'Session',
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
