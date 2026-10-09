import 'package:flutter/material.dart';

import '../../services/onboarding_store.dart';
import '../../widgets/auth_gate.dart';
import 'mindcare_onboarding_screen.dart';

class MindCareIntroFlow extends StatefulWidget {
  const MindCareIntroFlow({super.key});

  @override
  State<MindCareIntroFlow> createState() => _MindCareIntroFlowState();
}

class _MindCareIntroFlowState extends State<MindCareIntroFlow> {
  _IntroStage _stage = _IntroStage.checking;

  @override
  void initState() {
    super.initState();
    _restoreIntroState();
  }

  Future<void> _restoreIntroState() async {
    var completed = false;
    try {
      completed = await OnboardingStore.hasCompleted();
    } catch (_) {
      // If local persistence is unavailable, keep onboarding accessible.
    }
    if (mounted) {
      setState(() {
        _stage = completed ? _IntroStage.app : _IntroStage.onboarding;
      });
    }
  }

  Future<void> _continueToApp() async {
    try {
      await OnboardingStore.markCompleted();
    } catch (_) {
      // Continue into the app even if the device cannot persist this flag.
    }
    if (mounted) setState(() => _stage = _IntroStage.app);
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 420),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    child: switch (_stage) {
      _IntroStage.checking => const Scaffold(
        key: ValueKey('checking-onboarding'),
        body: Center(child: CircularProgressIndicator()),
      ),
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

enum _IntroStage { checking, onboarding, app }
