import 'package:flutter/material.dart';

import '../../theme/mindcare_intro_tokens.dart';

class PrivacyIllustration extends StatelessWidget {
  const PrivacyIllustration({super.key});

  @override
  Widget build(BuildContext context) => _IllustrationCanvas(
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: MindCareIntroTokens.mint.withValues(alpha: .2), width: 1.5),
          ),
        ),
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .48),
            border: Border.all(color: MindCareIntroTokens.primary.withValues(alpha: .12)),
          ),
        ),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: MindCareIntroTokens.darkGreen,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [BoxShadow(color: Color(0x2507520D), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 44),
        ),
        Positioned(
          bottom: 15,
          left: 12,
          child: _FloatingLabel(
            icon: Icons.visibility_off_outlined,
            title: 'Confidential',
            subtitle: 'Only you can see this',
          ),
        ),
        Positioned(
          bottom: 18,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: MindCareIntroTokens.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              "Here when\nyou're ready",
              style: TextStyle(color: Colors.white, fontSize: 11, height: 1.2, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    ),
  );
}

class CounselorIllustration extends StatelessWidget {
  const CounselorIllustration({super.key});

  @override
  Widget build(BuildContext context) => _IllustrationCanvas(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: 12,
          bottom: 21,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
            decoration: BoxDecoration(
              color: MindCareIntroTokens.primary,
              borderRadius: BorderRadius.circular(99),
              boxShadow: const [BoxShadow(color: Color(0x2607520D), blurRadius: 14, offset: Offset(0, 7))],
            ),
            child: const Text('A few taps', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          top: 27,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [BoxShadow(color: Color(0x180B7A14), blurRadius: 22, offset: Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(color: MindCareIntroTokens.softGreen, shape: BoxShape.circle),
                          child: const Icon(Icons.person_rounded, color: MindCareIntroTokens.primary, size: 30),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(width: 13, height: 13, decoration: BoxDecoration(color: MindCareIntroTokens.mint, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                        ),
                      ],
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dr. Maya Chen', style: TextStyle(color: MindCareIntroTokens.ink, fontSize: 15, fontWeight: FontWeight.w900)),
                          SizedBox(height: 3),
                          Text('Stress & academic wellbeing', style: TextStyle(color: MindCareIntroTokens.muted, fontSize: 10)),
                        ],
                      ),
                    ),
                    const Icon(Icons.verified_rounded, color: MindCareIntroTokens.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: MindCareIntroTokens.paleGreen, borderRadius: BorderRadius.circular(99)),
                  child: const Text('CAMPUS VERIFIED', style: TextStyle(color: MindCareIntroTokens.primary, fontSize: 8, letterSpacing: .8, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Text('Today · 2:30 PM', style: TextStyle(color: MindCareIntroTokens.ink, fontWeight: FontWeight.w800, fontSize: 12))),
                    Container(width: 29, height: 29, decoration: const BoxDecoration(color: MindCareIntroTokens.softGreen, shape: BoxShape.circle), child: const Icon(Icons.chevron_right_rounded, color: MindCareIntroTokens.primary, size: 20)),
                  ],
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: MindCareIntroTokens.primary, size: 13),
                    SizedBox(width: 5),
                    Text('Private booking · no phone call needed', style: TextStyle(color: MindCareIntroTokens.muted, fontSize: 9, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class InsightsIllustration extends StatefulWidget {
  const InsightsIllustration({super.key});

  @override
  State<InsightsIllustration> createState() => _InsightsIllustrationState();
}

class _InsightsIllustrationState extends State<InsightsIllustration> {
  int _selected = 2;
  static const _faces = ['😔', '😐', '🙂', '😄'];

  @override
  Widget build(BuildContext context) => _IllustrationCanvas(
    child: Stack(
      children: [
        Positioned(
          left: 17,
          right: 17,
          top: 14,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x180B7A14), blurRadius: 17, offset: Offset(0, 7))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily check-in', style: TextStyle(color: MindCareIntroTokens.primary, fontSize: 10, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                const Text('How are you feeling?', style: TextStyle(color: MindCareIntroTokens.ink, fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(_faces.length, (index) {
                    final selected = index == _selected;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13),
                          onTap: () => setState(() => _selected = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 40,
                            decoration: BoxDecoration(color: selected ? MindCareIntroTokens.paleGreen : const Color(0xFFF4F7F4), borderRadius: BorderRadius.circular(13), border: Border.all(color: selected ? MindCareIntroTokens.primary : Colors.transparent, width: 1.5)),
                            alignment: Alignment.center,
                            child: Text(_faces[index], style: const TextStyle(fontSize: 19)),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 30,
          right: 30,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
            decoration: BoxDecoration(color: MindCareIntroTokens.darkGreen, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x2407520D), blurRadius: 12, offset: Offset(0, 6))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('YOUR WEEK', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 7),
                const _WeekDots(),
                const SizedBox(height: 7),
                const Text('You feel steadier on days with a midday pause.', style: TextStyle(color: Colors.white, fontSize: 9, height: 1.25, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _WeekDots extends StatelessWidget {
  const _WeekDots();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [10.0, 16.0, 12.0, 22.0, 27.0, 18.0, 24.0]
        .asMap()
        .entries
        .map((entry) => Container(
          width: 8,
          height: entry.value,
          decoration: BoxDecoration(color: entry.key == 5 ? MindCareIntroTokens.mint : const Color(0xA6FFFFFF), borderRadius: BorderRadius.circular(99)),
        ))
        .toList(),
  );
}

class _FloatingLabel extends StatelessWidget {
  const _FloatingLabel({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x170B7A14), blurRadius: 12, offset: Offset(0, 5))]),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: MindCareIntroTokens.primary, size: 20),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: MindCareIntroTokens.ink, fontSize: 9, fontWeight: FontWeight.w900)),
            Text(subtitle, style: const TextStyle(color: MindCareIntroTokens.muted, fontSize: 7)),
          ],
        ),
      ],
    ),
  );
}

class _IllustrationCanvas extends StatelessWidget {
  const _IllustrationCanvas({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: Container(
      width: double.infinity,
      height: 250,
      decoration: const BoxDecoration(gradient: MindCareIntroTokens.pageBackground),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -48,
            child: Container(width: 145, height: 145, decoration: BoxDecoration(color: MindCareIntroTokens.mint.withValues(alpha: .1), shape: BoxShape.circle)),
          ),
          Positioned.fill(child: child),
        ],
      ),
    ),
  );
}
