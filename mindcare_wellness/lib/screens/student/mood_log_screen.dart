import 'package:flutter/material.dart';

import '../../services/mood_service.dart';
import 'mood_saved_screen.dart';
import 'weekly_wellbeing_screen.dart';

class MoodLogScreen extends StatefulWidget {
  const MoodLogScreen({
    super.key,
    this.entryId,
    this.initialMoodScore,
    this.initialStressLevel,
    this.initialNote,
    this.onBackHome,
  });

  final String? entryId;
  final int? initialMoodScore;
  final int? initialStressLevel;
  final String? initialNote;
  final VoidCallback? onBackHome;

  bool get isEditing => entryId != null;

  @override
  State<MoodLogScreen> createState() => _MoodLogScreenState();
}

class _MoodLogScreenState extends State<MoodLogScreen> {
  late int selectedMood;
  late int selectedStress;

  final MoodService _moodService = MoodService();
  final TextEditingController triggerController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    selectedMood = widget.initialMoodScore ?? 4;
    selectedStress = widget.initialStressLevel ?? 2;
    triggerController.text = widget.initialNote ?? '';
  }

  String get selectedMoodName {
    switch (selectedMood) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return 'Okay';
    }
  }

  Future<void> _saveMood() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final note = triggerController.text.trim();

      String entryId;

      if (widget.isEditing) {
        entryId = widget.entryId!;

        await _moodService.update(
          entryId,
          mood: selectedMoodName,
          moodScore: selectedMood,
          stressLevel: selectedStress,
          note: note.isEmpty ? null : note,
        );
      } else {
        entryId = await _moodService.create(
          mood: selectedMoodName,
          moodScore: selectedMood,
          stressLevel: selectedStress,
          note: note.isEmpty ? null : note,
        );
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MoodSavedScreen(
            mood: selectedMoodName,
            moodScore: selectedMood,
            stressLevel: selectedStress,
            note: note.isEmpty ? null : note,

            onViewWeeklyTrend: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                 builder: (context) => WeeklyWellbeingScreen(
                   onBackHome: widget.onBackHome,
), 
                ),
              );
            },

            onBackHome: () {
                    Navigator.of(context).pop();
                    widget.onBackHome?.call();
},

            onEditToday: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MoodLogScreen(
                    entryId: entryId,
                    initialMoodScore: selectedMood,
                    initialStressLevel: selectedStress,
                    initialNote: note.isEmpty ? null : note,
                    onBackHome: widget.onBackHome,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Unable to update mood: $error'
                : 'Unable to save mood: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    triggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF059669),
          ),
         onPressed: () {
  if (widget.onBackHome != null) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onBackHome!();
  } else {
    Navigator.maybePop(context);
  }
},
        ),
        title: Text(
          widget.isEditing
              ? 'Edit Daily Check In'
              : 'Daily Pulse Check In',
          style: const TextStyle(
            color: Color(0xFF059669),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF059669),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.isEditing
                              ? 'EDIT TODAY\'S CHECK-IN'
                              : 'STEP 01 OF 03 : DAILY PULSE',
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Text(
                        'DATE: 21 SEP',
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'MONDAY, 21 SEPTEMBER',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.isEditing
                        ? 'Update how you are feeling'
                        : 'How are you feeling today?',
                    style: const TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Tap the icon that best represents your baseline emotional energy right now.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      _moodBox(
                        1,
                        '01',
                        '😣',
                        'Very Low',
                        Colors.red.shade50,
                      ),
                      _moodBox(
                        2,
                        '02',
                        '☹️',
                        'Low',
                        Colors.orange.shade50,
                      ),
                      _moodBox(
                        3,
                        '03',
                        '😐',
                        'Okay',
                        Colors.amber.shade50,
                      ),
                      _moodBox(
                        4,
                        '04',
                        '🙂',
                        'Good',
                        Colors.green.shade50,
                      ),
                      _moodBox(
                        5,
                        '05',
                        '😊',
                        'Great',
                        Colors.blue.shade50,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.green.shade100,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '● STRESS LEVEL ASSESSMENT',
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SCALE (1-5)',
                                style: TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Rate your perceived tension and academic pressure today.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: List.generate(
                            5,
                            (index) {
                              final level = index + 1;
                              final selected =
                                  selectedStress == level;

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedStress = level;
                                    });
                                  },
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFF2FAF4),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            Colors.green.shade100,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$level',
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '1 = MINIMAL',
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 9,
                              ),
                            ),
                            Text(
                              '5 = SEVERE',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CONTEXT & TRIGGERS',
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'OPTIONAL',
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: triggerController,
                    maxLines: 4,
                    maxLength: 248,
                    decoration: InputDecoration(
                      hintText:
                          'What factors influenced your status today? (e.g. exams, sleep, workload)',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.green.shade100,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.green.shade100,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFA7F3D0),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: Color(0xFF059669),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'End-to-end encrypted. Logs are strictly visible to you and assigned wellness staff upon explicit appointment request.',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _isSaving ? null : _saveMood,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.isEditing
                                  ? 'UPDATE MOOD ENTRY'
                                  : 'SAVE MOOD ENTRY',
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                           builder: (context) => WeeklyWellbeingScreen(
                             onBackHome: widget.onBackHome,
),
                          ),
                        );
                      },
                      child: const Text(
                        '[ VIEW HISTORICAL MOOD TRENDS ]',
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),

                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _moodBox(
    int value,
    String number,
    String emoji,
    String label,
    Color color,
  ) {
    final selected = selectedMood == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedMood = value;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 3,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFF059669)
                  : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                emoji,
                style: const TextStyle(
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}