import 'package:flutter/material.dart';

import '../../../models/counselor_models.dart';
import '../../../services/counselor_service.dart';
import '../counselor_theme.dart';

class CounselorReportsScreen extends StatefulWidget {
  const CounselorReportsScreen({required this.service, super.key});

  final CounselorService service;

  @override
  State<CounselorReportsScreen> createState() => _CounselorReportsScreenState();
}

class _CounselorReportsScreenState extends State<CounselorReportsScreen> {
  _ReportRange _range = _ReportRange.thisWeek;
  DateTimeRange? _customRange;

  DateTimeRange get _selectedRange => _customRange ?? _range.range(DateTime.now());

  Future<void> _selectRange(_ReportRange range) async {
    if (range != _ReportRange.custom) {
      setState(() {
        _range = range;
        _customRange = null;
      });
      return;
    }
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _customRange ?? _ReportRange.thisWeek.range(now),
      helpText: 'Select report period',
    );
    if (picked != null && mounted) {
      setState(() {
        _range = _ReportRange.custom;
        _customRange = DateTimeRange(
          start: _dayStart(picked.start),
          end: _dayEnd(picked.end),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: StreamBuilder<List<CounselorAppointment>>(
      stream: widget.service.appointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: dashboardGreen));
        }
        if (snapshot.hasError) {
          return _ReportError(onRetry: () => setState(() {}));
        }
        final range = _selectedRange;
        final appointments = (snapshot.data ?? const <CounselorAppointment>[])
            .where((item) => _inRange(item.startAt, range))
            .toList()
          ..sort((a, b) => (a.startAt ?? DateTime(2100)).compareTo(b.startAt ?? DateTime(2100)));
        final report = _ReportData(appointments: appointments, range: range);
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
          children: [
            const ReportsHeader(),
            const SizedBox(height: 16),
            const Text(
              'View your counseling activity and appointment statistics.',
              style: TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
            const SizedBox(height: 13),
            _RangeSelector(
              range: _range,
              customRange: _customRange,
              onChanged: _selectRange,
            ),
            const SizedBox(height: 18),
            const Text('Weekly Overview', style: TextStyle(color: dashboardInk, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            _SummaryGrid(report: report),
            const SizedBox(height: 16),
            _ActivityChart(report: report),
            const SizedBox(height: 14),
            _StatusCard(report: report),
            const SizedBox(height: 14),
            _SessionTypeCard(report: report),
            const SizedBox(height: 14),
            _ActivitySummary(report: report),
          ],
        );
      },
    ),
  );
}

class ReportsHeader extends StatelessWidget {
  const ReportsHeader({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: const Color(0xFFD5F8DF), borderRadius: BorderRadius.circular(9)),
        child: const Icon(Icons.bar_chart_outlined, color: dashboardGreen, size: 20),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('COUNSELOR PORTAL', style: TextStyle(color: dashboardGreen, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .6)),
            Text('Reports', style: TextStyle(color: dashboardInk, fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      const _LiveBadge(),
    ],
  );
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(color: const Color(0xFFD8F8E0), borderRadius: BorderRadius.circular(13)),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: dashboardBright, size: 8),
        SizedBox(width: 5),
        Text('Live sync', style: TextStyle(color: dashboardGreen, fontSize: 9, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.range, required this.customRange, required this.onChanged});
  final _ReportRange range;
  final DateTimeRange? customRange;
  final ValueChanged<_ReportRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedDates = customRange ?? range.range(DateTime.now());
    final selectedLabel =
      '${range.label}: ${_date(selectedDates.start)} - ${_date(selectedDates.end.subtract(const Duration(days: 1)))}';
    return InkWell(
      onTap: () async {
        final value = await showModalBottomSheet<_ReportRange>(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _ReportRange.values.map((item) => ListTile(
                leading: Icon(item == _ReportRange.custom ? Icons.date_range : Icons.calendar_today_outlined, color: dashboardGreen),
                title: Text(item.label),
                trailing: item == range ? const Icon(Icons.check, color: dashboardGreen) : null,
                onTap: () => Navigator.pop(context, item),
              )).toList(),
            ),
          ),
        );
        if (value != null) onChanged(value);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 9, 9),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF9BDEB0))),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 15, color: dashboardGreen),
            const SizedBox(width: 8),
            const Text('Date range', style: TextStyle(color: Colors.blueGrey, fontSize: 10)),
            const SizedBox(width: 8),
            Expanded(child: Text(selectedLabel, textAlign: TextAlign.right, style: const TextStyle(color: dashboardInk, fontSize: 11, fontWeight: FontWeight.w800))),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.blueGrey),
          ],
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.report});
  final _ReportData report;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(children: [
        Expanded(child: _MetricCard(label: 'Total Sessions', value: report.total, icon: Icons.groups_2_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _MetricCard(label: 'Completed', value: report.completed, icon: Icons.check_circle_outline)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _MetricCard(label: 'Pending', value: report.pending, icon: Icons.pending_actions_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _MetricCard(label: 'Cancelled', value: report.cancelled, icon: Icons.cancel_outlined)),
      ]),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    height: 88,
    padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD7F1DF))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 10))), Icon(icon, color: dashboardGreen, size: 16)]),
        const Spacer(),
        Text('$value', style: const TextStyle(color: dashboardInk, fontSize: 24, fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.report});
  final _ReportData report;

  @override
  Widget build(BuildContext context) {
    final peak = report.days.reduce((a, b) => a.count >= b.count ? a : b);
    final maxValue = report.days.fold<int>(0, (max, day) => day.count > max ? day.count : max);
    final chartWidth = report.days.length > 7 ? report.days.length * 43.0 : 7 * 43.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD7F1DF))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Appointment Activity', style: TextStyle(color: dashboardInk, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          const Text('Sessions during the selected period', style: TextStyle(color: Colors.blueGrey, fontSize: 10)),
          const SizedBox(height: 13),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: chartWidth,
              height: 190,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: report.days.map((day) => _ReportBar(
                  day: day,
                  maxValue: maxValue,
                  isPeak: day == peak && peak.count > 0,
                  onTap: () => _showDayDetails(context, day),
                )).toList(),
              ),
            ),
          ),
          const Divider(height: 16),
          Text(
            peak.count == 0 ? 'No appointments in this period.' : 'Peak activity: ${peak.label} · ${peak.count} sessions',
            style: const TextStyle(color: dashboardInk, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  void _showDayDetails(BuildContext context, _DayReport day) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(day.longLabel, style: const TextStyle(color: dashboardInk, fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _DetailStat(label: 'Appointments', value: day.count),
              _DetailStat(label: 'Completed', value: day.completed),
              _DetailStat(label: 'Confirmed', value: day.confirmed),
              _DetailStat(label: 'Cancelled', value: day.cancelled),
              _DetailStat(label: 'Pending', value: day.pending),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportBar extends StatelessWidget {
  const _ReportBar({required this.day, required this.maxValue, required this.isPeak, required this.onTap});
  final _DayReport day;
  final int maxValue;
  final bool isPeak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final height = day.count == 0 ? 4.0 : 86 * (day.count / (maxValue == 0 ? 1 : maxValue));
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: 28, child: isPeak ? const _PeakLabel() : Text('${day.count}', textAlign: TextAlign.center, style: const TextStyle(color: dashboardInk, fontSize: 10, fontWeight: FontWeight.w700))),
            Container(width: 22, height: height, decoration: BoxDecoration(color: isPeak ? const Color(0xFF10D51A) : dashboardGreen, borderRadius: const BorderRadius.vertical(top: Radius.circular(5)))),
            const SizedBox(height: 6),
            Text(day.label, style: TextStyle(color: isPeak ? dashboardGreen : Colors.blueGrey, fontSize: 9, fontWeight: isPeak ? FontWeight.w800 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _PeakLabel extends StatelessWidget {
  const _PeakLabel();
  @override
  Widget build(BuildContext context) => const Column(children: [Text('Peak', style: TextStyle(color: dashboardGreen, fontSize: 8, fontWeight: FontWeight.w800)), SizedBox(height: 3), Text(' ', style: TextStyle(fontSize: 10))]);
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.report});
  final _ReportData report;

  @override
  Widget build(BuildContext context) => _ReportCard(
    title: 'Appointment status',
    child: Column(children: [
      _ProgressRow(label: 'Completed', value: report.completed, total: report.total, color: dashboardGreen),
      _ProgressRow(label: 'Confirmed', value: report.confirmed, total: report.total, color: const Color(0xFF6BDB4B)),
      _ProgressRow(label: 'Pending', value: report.pending, total: report.total, color: Colors.orange),
      _ProgressRow(label: 'Cancelled', value: report.cancelled, total: report.total, color: Colors.redAccent),
      _ProgressRow(label: 'No-show', value: report.noShows, total: report.total, color: Colors.blueGrey),
    ]),
  );
}

class _SessionTypeCard extends StatelessWidget {
  const _SessionTypeCard({required this.report});
  final _ReportData report;

  @override
  Widget build(BuildContext context) => _ReportCard(
    title: 'Session types',
    child: Column(children: report.sessionTypes.entries.map((entry) => _ProgressRow(label: _sessionType(entry.key), value: entry.value, total: report.total, color: dashboardGreen)).toList()),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD7F1DF))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: dashboardInk, fontSize: 14, fontWeight: FontWeight.w800)), const SizedBox(height: 12), child]),
  );
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.value, required this.total, required this.color});
  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      SizedBox(width: 88, child: Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 11))),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: total == 0 ? 0 : value / total, minHeight: 8, backgroundColor: const Color(0xFFEAF5ED), color: color))),
      SizedBox(width: 32, child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(color: dashboardInk, fontWeight: FontWeight.w800))),
    ]),
  );
}

class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary({required this.report});
  final _ReportData report;

  @override
  Widget build(BuildContext context) => _ReportCard(
    title: 'Additional statistics',
    child: Column(children: [
      _DetailStat(label: 'Unique students seen', value: report.uniqueStudents),
      _DetailStat(label: 'Most active day', value: report.peakDay.count == 0 ? 0 : report.peakDay.count, suffix: report.peakDay.count == 0 ? 'No activity' : report.peakDay.longLabel),
      _DetailStat(label: 'Completed rate', value: report.total == 0 ? 0 : ((report.completed / report.total) * 100).round(), suffix: '%'),
    ]),
  );
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({required this.label, required this.value, this.suffix});
  final String label;
  final int value;
  final String? suffix;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 12))), Text('$value${suffix == null ? '' : ' $suffix'}', style: const TextStyle(color: dashboardInk, fontWeight: FontWeight.w800))]));
}

class _ReportError extends StatelessWidget {
  const _ReportError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_outlined, color: dashboardGreen, size: 42), const SizedBox(height: 12), const Text('Unable to load reports.', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 5), const Text('Please check your connection and try again.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)), const SizedBox(height: 14), OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry'))])));
}

class _ReportData {
  _ReportData({required this.appointments, required this.range}) {
    total = appointments.length;
    completed = _count('completed');
    pending = _count('pending');
    confirmed = _count('confirmed');
    cancelled = _count('cancelled');
    noShows = appointments.where((item) => item.status == 'no_show' || item.status == 'no-show' || item.status == 'missed').length;
    uniqueStudents = appointments.map((item) => item.studentId).where((id) => id.isNotEmpty).toSet().length;
    for (final item in appointments) {
      final type = item.sessionType;
      sessionTypes[type] = (sessionTypes[type] ?? 0) + 1;
    }
    days = _buildDays();
    peakDay = days.reduce((a, b) => a.count >= b.count ? a : b);
  }

  final List<CounselorAppointment> appointments;
  final DateTimeRange range;
  late int total;
  late int completed;
  late int pending;
  late int confirmed;
  late int cancelled;
  late int noShows;
  late int uniqueStudents;
  late List<_DayReport> days;
  late _DayReport peakDay;
  final Map<String, int> sessionTypes = {};

  int _count(String status) => appointments.where((item) => item.status == status).length;

  List<_DayReport> _buildDays() {
    final result = <_DayReport>[];
    for (var date = _dayStart(range.start); date.isBefore(range.end); date = date.add(const Duration(days: 1))) {
      final dayAppointments = appointments.where((item) => _sameDay(item.startAt, date)).toList();
      result.add(_DayReport(date: date, appointments: dayAppointments));
    }
    return result;
  }
}

class _DayReport {
  _DayReport({required this.date, required this.appointments});
  final DateTime date;
  final List<CounselorAppointment> appointments;
  int get count => appointments.length;
  int get completed => appointments.where((item) => item.status == 'completed').length;
  int get confirmed => appointments.where((item) => item.status == 'confirmed').length;
  int get cancelled => appointments.where((item) => item.status == 'cancelled').length;
  int get pending => appointments.where((item) => item.status == 'pending').length;
  String get label => _weekdays[date.weekday - 1];
  String get longLabel => '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]} ${date.year}';
}

enum _ReportRange {
  thisWeek('This Week'),
  thisMonth('This Month'),
  last7('Last 7 Days'),
  last30('Last 30 Days'),
  custom('Custom Range');

  const _ReportRange(this.label);
  final String label;

  DateTimeRange range(DateTime now) {
    final today = _dayStart(now);
    return switch (this) {
      _ReportRange.thisWeek => DateTimeRange(start: today.subtract(Duration(days: today.weekday - 1)), end: today.subtract(Duration(days: today.weekday - 1)).add(const Duration(days: 7))),
      _ReportRange.thisMonth => DateTimeRange(start: DateTime(today.year, today.month), end: DateTime(today.year, today.month + 1)),
      _ReportRange.last7 => DateTimeRange(start: today.subtract(const Duration(days: 6)), end: _dayEnd(today)),
      _ReportRange.last30 => DateTimeRange(start: today.subtract(const Duration(days: 29)), end: _dayEnd(today)),
      _ReportRange.custom => DateTimeRange(start: today, end: _dayEnd(today)),
    };
  }
}

bool _inRange(DateTime? value, DateTimeRange range) => value != null && !value.isBefore(range.start) && value.isBefore(range.end);
bool _sameDay(DateTime? a, DateTime b) => a != null && a.year == b.year && a.month == b.month && a.day == b.day;
DateTime _dayStart(DateTime date) => DateTime(date.year, date.month, date.day);
DateTime _dayEnd(DateTime date) => _dayStart(date).add(const Duration(days: 1));
String _date(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';
String _sessionType(String value) => switch (value) { 'video' => 'Video', 'audio' => 'Audio', 'in_person' => 'In-person', 'chat' => 'Chat', _ => value };
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
