import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/mood_entry_model.dart';
import '../../services/mood_service.dart';
import 'mood_log_screen.dart';

class WeeklyWellbeingScreen extends StatelessWidget {
  WeeklyWellbeingScreen({super.key});

  final MoodService _moodService = MoodService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFFF2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            child: Column(
              children: [
                _topBar(context),

                Expanded(
                  child: StreamBuilder<List<MoodEntryModel>>(
                    stream: _moodService.mine(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00B72B),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Unable to load mood history.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }

                      final entries = snapshot.data ?? [];

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _flowRow(),

                            const SizedBox(height: 14),

                            _weeklyChartCard(entries),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: _summaryCard(
                                    title: 'Avg. Mood',
                                    value: _averageMood(entries),
                                    subtitle: 'Consistent',
                                  ),
                                ),

                                const SizedBox(width: 7),

                                Expanded(
                                  child: _summaryCard(
                                    title: 'Check-ins',
                                    value:
                                        '${math.min(entries.length, 7)}/7 d',
                                    subtitle: 'Great habit',
                                  ),
                                ),

                                const SizedBox(width: 7),

                                Expanded(
                                  child: _summaryCard(
                                    title: 'Trend',
                                    value: _trendLabel(entries),
                                    subtitle: 'Vs last wk',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            const Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 12,
                                  color: Color(0xFF419B55),
                                ),
                                SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'Summary based strictly on self check-ins. This is not a formal medical diagnosis.',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent Check-Ins',
                                  style: TextStyle(
                                    color: Color(0xFF078D25),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE7FF75),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'LAST 5 ENTRIES',
                                    style: TextStyle(
                                      color: Color(0xFF078D25),
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            if (entries.isEmpty)
                              _emptyCard()
                            else
                              ...entries.take(5).map(
                                    (entry) => _entryCard(
                                      context,
                                      entry,
                                    ),
                                  ),

                            const SizedBox(height: 14),

                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const MoodLogScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF00C92D),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  '⊕  Check In Today',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 9),

                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      const Color(0xFF078D25),
                                  side: const BorderSide(
                                    color: Color(0xFF078D25),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  '⌂  Get Counseling Support',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Container(
      height: 58,
      color: const Color(0xFFE3FFE8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF078D25),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),

          const Expanded(
            child: Center(
              child: Text(
                'Weekly Wellbeing',
                style: TextStyle(
                  color: Color(0xFF078D25),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF08A92C),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _flowRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE7FF75),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            '● FLOW 1 : WEEKLY_TREND',
            style: TextStyle(
              color: Color(0xFF078D25),
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFF90D89D),
            ),
          ),
          child: const Row(
            children: [
              Text(
                'Last 7 Days',
                style: TextStyle(
                  color: Color(0xFF078D25),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down,
                size: 13,
                color: Color(0xFF078D25),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _weeklyChartCard(List<MoodEntryModel> entries) {
    final scores = entries
        .take(7)
        .toList()
        .reversed
        .map(
          (entry) => entry.moodScore.toDouble(),
        )
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFC9EED0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Mood This Week',
                    style: TextStyle(
                      color: Color(0xFF078D25),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'MON - SUN',
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7FF75),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF078D25),
                  size: 17,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            '5 Great',
            style: TextStyle(
              color: Color(0xFF64B800),
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          if (scores.isEmpty)
            const SizedBox(
              height: 150,
              child: Center(
                child: Text(
                  'No mood check-ins yet.',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 10,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 165,
              width: double.infinity,
              child: CustomPaint(
                painter: _MoodTrendPainter(scores),
                child: const Padding(
                  padding: EdgeInsets.only(
                    left: 35,
                    right: 8,
                    bottom: 4,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mon',
                          style: TextStyle(fontSize: 7),
                        ),
                        Text(
                          'Tue',
                          style: TextStyle(fontSize: 7),
                        ),
                        Text(
                          'Wed',
                          style: TextStyle(fontSize: 7),
                        ),
                        Text(
                          'Thu',
                          style: TextStyle(fontSize: 7),
                        ),
                        Text(
                          'Fri',
                          style: TextStyle(fontSize: 7),
                        ),
                        Text(
                          'Sat',
                          style: TextStyle(fontSize: 7),
                        ),
                        Text(
                          'Sun',
                          style: TextStyle(fontSize: 7),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC9EED0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF078D25),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE7FF75),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF078D25),
                fontSize: 7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryCard(
    BuildContext context,
    MoodEntryModel entry,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC9EED0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE7FF75),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFB5E830),
              ),
            ),
            child: Text(
              entry.moodScore.toStringAsFixed(1),
              style: const TextStyle(
                color: Color(0xFF078D25),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _entryTitle(entry),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    if (entry.createdAt != null)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFDAF7DE),
                          borderRadius:
                              BorderRadius.circular(7),
                        ),
                        child: Text(
                          _timeText(entry.createdAt!),
                          style: const TextStyle(
                            fontSize: 6,
                            color: Color(0xFF078D25),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 3),

                Text(
                  'Mood: ${entry.mood} (${entry.moodScore}/5)  •  Stress: ${_stressLabel(entry.stressLevel)} (${entry.stressLevel ?? '-'}/5)',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 8,
                  ),
                ),

                if (entry.note != null &&
                    entry.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),

                  Text(
                    entry.note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 7,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 5),

          IconButton(
            tooltip: 'Delete mood entry',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
              size: 20,
            ),
            onPressed: () {
              _confirmDelete(
                context,
                entry,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MoodEntryModel entry,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Mood Entry?',
          ),
          content: Text(
            'Are you sure you want to delete the "${entry.mood}" mood check-in? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _moodService.delete(
        entry.id,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mood entry deleted successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete mood entry: $error',
          ),
        ),
      );
    }
  }

  Widget _emptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Your saved mood entries will appear here.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black54,
          fontSize: 10,
        ),
      ),
    );
  }

  String _averageMood(
    List<MoodEntryModel> entries,
  ) {
    if (entries.isEmpty) return '0.0/5';

    final recent = entries.take(7).toList();

    final total = recent.fold<int>(
      0,
      (sum, entry) => sum + entry.moodScore,
    );

    final average = total / recent.length;

    return '${average.toStringAsFixed(1)}/5';
  }

  String _trendLabel(
    List<MoodEntryModel> entries,
  ) {
    if (entries.length < 2) {
      return 'New';
    }

    final recent = entries.take(2).toList();

    if (recent[0].moodScore >
        recent[1].moodScore) {
      return 'Improving';
    }

    if (recent[0].moodScore <
        recent[1].moodScore) {
      return 'Lower';
    }

    return 'Steady';
  }

  String _stressLabel(int? level) {
    if (level == null) return 'N/A';

    if (level <= 2) return 'Low';

    if (level == 3) return 'Med';

    return 'High';
  }

  String _entryTitle(
    MoodEntryModel entry,
  ) {
    final date = entry.createdAt;

    if (date == null) {
      return entry.mood;
    }

    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return '${days[date.weekday - 1]}, ${entry.mood}';
  }

  String _timeText(DateTime date) {
    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class _MoodTrendPainter extends CustomPainter {
  _MoodTrendPainter(this.values);

  final List<double> values;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    const left = 36.0;
    const top = 8.0;
    const bottom = 25.0;
    const right = 10.0;

    final chartWidth =
        size.width - left - right;

    final chartHeight =
        size.height - top - bottom;

    final gridPaint = Paint()
      ..color = const Color(0xFFD8F4DE)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = const Color(0xFF05B62B)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = const Color(0xFF05B62B)
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..color = const Color(0xFF8BE99B).withValues(
        alpha: 0.18,
      )
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final y =
          top + (chartHeight / 4) * i;

      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    const labels = [
      '5 Great',
      '4 Good',
      '3 Okay',
      '2 Low',
      '1 V.Low',
    ];

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0;
        i < labels.length;
        i++) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(
          fontSize: 7,
          color: Color(0xFF6D8C73),
        ),
      );

      textPainter.layout();

      final y =
          top + (chartHeight / 4) * i;

      textPainter.paint(
        canvas,
        Offset(
          0,
          y - textPainter.height / 2,
        ),
      );
    }

    if (values.isEmpty) return;

    final normalized = List<double>.filled(
      7,
      values.first,
    );

    for (int i = 0;
        i < values.length && i < 7;
        i++) {
      normalized[i] = values[i];
    }

    if (values.length < 7) {
      for (int i = values.length;
          i < 7;
          i++) {
        normalized[i] =
            normalized[values.length - 1];
      }
    }

    final points = <Offset>[];

    for (int i = 0; i < 7; i++) {
      final x =
          left + chartWidth * (i / 6);

      final score =
          normalized[i].clamp(1.0, 5.0);

      final y = top +
          chartHeight *
              ((5.0 - score) / 4.0);

      points.add(
        Offset(x, y),
      );
    }

    final path = Path()
      ..moveTo(
        points.first.dx,
        points.first.dy,
      );

    for (int i = 1;
        i < points.length;
        i++) {
      path.lineTo(
        points[i].dx,
        points[i].dy,
      );
    }

    final fillPath = Path.from(path)
      ..lineTo(
        points.last.dx,
        top + chartHeight,
      )
      ..lineTo(
        points.first.dx,
        top + chartHeight,
      )
      ..close();

    canvas.drawPath(
      fillPath,
      fillPaint,
    );

    canvas.drawPath(
      path,
      linePaint,
    );

    for (final point in points) {
      canvas.drawCircle(
        point,
        3.5,
        pointPaint,
      );

      canvas.drawCircle(
        point,
        1.6,
        Paint()
          ..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _MoodTrendPainter oldDelegate,
  ) {
    return oldDelegate.values != values;
  }
}