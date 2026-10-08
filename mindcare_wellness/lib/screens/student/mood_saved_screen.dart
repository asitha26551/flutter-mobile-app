import 'package:flutter/material.dart';

class MoodSavedScreen extends StatelessWidget {
  const MoodSavedScreen({
    super.key,
    required this.mood,
    required this.moodScore,
    required this.stressLevel,
    this.note,
    required this.onViewWeeklyTrend,
    required this.onBackHome,
    required this.onEditToday,
  });

  final String mood;
  final int moodScore;
  final int stressLevel;
  final String? note;

  final VoidCallback onViewWeeklyTrend;
  final VoidCallback onBackHome;
  final VoidCallback onEditToday;

  String get stressText {
    if (stressLevel <= 2) {
      return 'LOW';
    } else if (stressLevel == 3) {
      return 'MEDIUM';
    } else {
      return 'HIGH';
    }
  }

  String get moodEmoji {
    switch (moodScore) {
      case 1:
        return '😣';
      case 2:
        return '☹️';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😊';
      default:
        return '😐';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            child: Column(
              children: [
                _topBar(),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      24,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '● FLOW : MOOD_TRACKER',
                              style: TextStyle(
                                color: Color(0xFF078D25),
                                fontSize: 7,
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'STEP 03 OF 03 : SAVED',
                                style: TextStyle(
                                  color: Color(0xFF078D25),
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: List.generate(
                            3,
                            (index) => Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(
                                  right: index == 2 ? 0 : 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00B62F),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9FF83),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFF8BEA38),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C92D),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFFF94),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            '✨ Great job checking in today!',
                            style: TextStyle(
                              color: Color(0xFF078D25),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Mood Saved',
                          style: TextStyle(
                            color: Color(0xFF078D25),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Your mood check-in for today has been recorded.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 10,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFFD9D4F5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '● ENTRY RECORD',
                                style: TextStyle(
                                  color: Color(0xFF078D25),
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 14),

                              const Text(
                                "Today's Summary",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const Divider(height: 24),

                              _summaryRow(
                                'SELECTED MOOD',
                                '$moodEmoji  ${mood.toUpperCase()}',
                              ),

                              const SizedBox(height: 14),

                              _summaryRow(
                                'MOOD SCORE',
                                '$moodScore / 5',
                              ),

                              const SizedBox(height: 14),

                              _summaryRow(
                                'STRESS LEVEL',
                                '$stressLevel / 5 ($stressText)',
                              ),

                              const SizedBox(height: 14),

                              const Text(
                                'NOTE RECORDED',
                                style: TextStyle(
                                  color: Color(0xFF078D25),
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 7),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7FFED),
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: const Color(0xFFB9EEC4),
                                  ),
                                ),
                                child: Text(
                                  note == null || note!.trim().isEmpty
                                      ? 'No context note added.'
                                      : note!,
                                  style: const TextStyle(
                                    color: Color(0xFF078D25),
                                    fontSize: 9,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FFF3),
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: const Color(0xFFC6EACC),
                                  ),
                                ),
                                child: const Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.verified_user_outlined,
                                      color: Color(0xFF078D25),
                                      size: 15,
                                    ),
                                    SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        'Data stored securely in your private wellness record.',
                                        style: TextStyle(
                                          color: Color(0xFF078D25),
                                          fontSize: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: onViewWeeklyTrend,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF00C92D),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'View Weekly Trend  ↗',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 9),

                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton(
                            onPressed: onBackHome,
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  const Color(0xFF078D25),
                              side: const BorderSide(
                                color: Color(0xFF078D25),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              '⌂  Back to Home',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextButton(
                          onPressed: onEditToday,
                          child: const Text(
                            '[ EDIT TODAY\'S CHECK-IN ]',
                            style: TextStyle(
                              color: Color(0xFF078D25),
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      height: 58,
      color: const Color(0xFFE3FFE8),
      child: const Row(
        children: [
          SizedBox(width: 48),
          Expanded(
            child: Center(
              child: Text(
                'Mood Saved',
                style: TextStyle(
                  color: Color(0xFF078D25),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
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

  Widget _summaryRow(
    String title,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 7,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE5FFEA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF078D25),
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}