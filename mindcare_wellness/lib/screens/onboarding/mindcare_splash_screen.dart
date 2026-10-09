import 'package:flutter/material.dart';

import '../../theme/mindcare_intro_tokens.dart';

class MindCareSplashScreen extends StatefulWidget {
  const MindCareSplashScreen({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  State<MindCareSplashScreen> createState() => _MindCareSplashScreenState();
}

class _MindCareSplashScreenState extends State<MindCareSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completed) {
        _completed = true;
        widget.onComplete();
      }
    });
    _progress.forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: MindCareIntroTokens.splashBackground,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: Column(
            children: [
              const Spacer(),
              const _SplashLogo(),
              const SizedBox(height: 28),
              const Text(
                'MINDCARE WELLNESS',
                style: TextStyle(
                  color: MindCareIntroTokens.mint,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.2,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Your wellbeing,\nheld with care.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'A confidential campus companion for support, reflection, and steadier days.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xD9FFFFFF),
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              const _SafetyChip(),
              const SizedBox(height: 18),
              SizedBox(
                width: 80,
                height: 5,
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _progress.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: MindCareIntroTokens.mint,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'A calmer space is opening',
                style: TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) => Container(
    width: 120,
    height: 120,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(32),
      boxShadow: const [
        BoxShadow(color: Color(0x42002D07), blurRadius: 30, offset: Offset(0, 15)),
      ],
    ),
    child: Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: MindCareIntroTokens.softGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.spa_rounded,
          size: 40,
          color: MindCareIntroTokens.primary,
        ),
      ),
    ),
  );
}

class _SafetyChip extends StatelessWidget {
  const _SafetyChip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withValues(alpha: .28)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline_rounded, color: Colors.white, size: 14),
        SizedBox(width: 7),
        Text(
          'CONFIDENTIAL • CAMPUS SAFENET',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    ),
  );
}
