import 'package:flutter/material.dart';

import '../../theme/mindcare_intro_tokens.dart';
import 'onboarding_illustrations.dart';

class MindCareOnboardingScreen extends StatefulWidget {
  const MindCareOnboardingScreen({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  State<MindCareOnboardingScreen> createState() =>
      _MindCareOnboardingScreenState();
}

class _MindCareOnboardingScreenState extends State<MindCareOnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPageData(
      tag: 'PRIVATE BY DESIGN',
      tagIcon: Icons.lock_outline_rounded,
      title: 'A safe space, without judgment',
      body:
          'Talk, reflect, or simply pause. Your wellbeing journey stays confidential and always moves at your pace.',
      note: 'Your activity is never shared with faculty.',
      illustration: PrivacyIllustration.new,
    ),
    _OnboardingPageData(
      tag: 'VERIFIED CAMPUS CARE',
      tagIcon: Icons.verified_user_outlined,
      title: 'The right support, a few taps away',
      body:
          'Explore verified counselors, find a time that works, and book securely without the usual back-and-forth.',
      note: 'Student-friendly availability, clearly shown.',
      illustration: CounselorIllustration.new,
    ),
    _OnboardingPageData(
      tag: 'PERSONALIZED INSIGHTS',
      tagIcon: Icons.insights_rounded,
      title: 'Small check-ins. Clearer patterns.',
      body:
          'Notice what lifts you up with quick mood check-ins and gentle insights shaped around your everyday life.',
      note: 'Insights are private, supportive, and yours to use.',
      illustration: InsightsIllustration.new,
    ),
  ];

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
      return;
    }
    _goTo(_page + 1);
  }

  void _finish() => widget.onComplete();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MindCareIntroTokens.scaffold,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
        child: Column(
          children: [
            _OnboardingHeader(page: _page, onSkip: _finish),
            const SizedBox(height: 14),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => _OnboardingContent(data: _pages[index]),
              ),
            ),
            const SizedBox(height: 12),
            _OnboardingFooter(
              page: _page,
              onBack: _page == 0 ? null : () => _goTo(_page - 1),
              onNext: _next,
            ),
          ],
        ),
      ),
    ),
  );
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.tag,
    required this.tagIcon,
    required this.title,
    required this.body,
    required this.note,
    required this.illustration,
  });

  final String tag;
  final IconData tagIcon;
  final String title;
  final String body;
  final String note;
  final Widget Function() illustration;
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.page, required this.onSkip});
  final int page;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(color: MindCareIntroTokens.softGreen, shape: BoxShape.circle),
          child: const Icon(Icons.spa_rounded, size: 20, color: MindCareIntroTokens.primary),
        ),
        const SizedBox(width: 9),
        const Text('MindCare', style: TextStyle(color: MindCareIntroTokens.ink, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -.4)),
        const Spacer(),
        if (page < 2)
          TextButton(onPressed: onSkip, style: TextButton.styleFrom(foregroundColor: MindCareIntroTokens.muted), child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w700)))
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: MindCareIntroTokens.paleGreen, borderRadius: BorderRadius.circular(99)),
            child: const Text('3 OF 3', style: TextStyle(color: MindCareIntroTokens.primary, fontSize: 10, letterSpacing: .8, fontWeight: FontWeight.w900)),
          ),
      ],
    ),
  );
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent({required this.data});
  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight - 8),
        child: Column(
          children: [
            data.illustration(),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: MindCareIntroTokens.paleGreen, borderRadius: BorderRadius.circular(99)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(data.tagIcon, color: MindCareIntroTokens.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(data.tag, style: const TextStyle(color: MindCareIntroTokens.primary, fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: MindCareIntroTokens.ink, fontSize: 27, height: 1.08, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
            ),
            const SizedBox(height: 9),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Text(data.body, textAlign: TextAlign.center, style: const TextStyle(color: MindCareIntroTokens.muted, fontSize: 13, height: 1.45)),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color(0x090B7A14), blurRadius: 10, offset: Offset(0, 3))]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: MindCareIntroTokens.primary, size: 17),
                  const SizedBox(width: 8),
                  Flexible(child: Text(data.note, textAlign: TextAlign.center, style: const TextStyle(color: MindCareIntroTokens.ink, fontSize: 11, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({required this.page, required this.onBack, required this.onNext});
  final int page;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 54,
    child: Row(
      children: [
        SizedBox(
          width: 94,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Back'),
            style: TextButton.styleFrom(foregroundColor: MindCareIntroTokens.muted, disabledForegroundColor: MindCareIntroTokens.muted.withValues(alpha: .35), padding: EdgeInsets.zero),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final active = index == page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 26 : 6,
                height: 6,
                decoration: BoxDecoration(color: active ? MindCareIntroTokens.primary : const Color(0xFFCAD7CC), borderRadius: BorderRadius.circular(99)),
              );
            }),
          ),
        ),
        SizedBox(
          width: 130,
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(backgroundColor: MindCareIntroTokens.primary, foregroundColor: Colors.white, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text(page == 2 ? 'Get started' : 'Next'), const SizedBox(width: 6), const Icon(Icons.arrow_forward_rounded, size: 16)],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
