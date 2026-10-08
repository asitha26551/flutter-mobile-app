import 'package:flutter/material.dart';

import '../../widgets/auth_gate.dart';
import 'mindcare_onboarding_screen.dart';

class MindCareIntroFlow extends StatefulWidget {
  const MindCareIntroFlow({super.key});

  @override
  State<MindCareIntroFlow> createState() => _MindCareIntroFlowState();
}

class _MindCareIntroFlowState extends State<MindCareIntroFlow> {
  _IntroStage _stage = _IntroStage.onboarding;

  void _continueToApp() => setState(() => _stage = _IntroStage.app);

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 420),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    child: switch (_stage) {
      _IntroStage.onboarding => MindCareOnboardingScreen(
        key: const ValueKey('onboarding'),
        onComplete: _continueToApp,
      ),
      _IntroStage.app => const AuthGate(
        key: ValueKey('app'),
      ),
    },
  );
}

enum _IntroStage {
  onboarding,
  app,
}