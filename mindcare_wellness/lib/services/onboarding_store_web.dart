import 'dart:html' as html;

const _key = 'mindcare.onboarding.completed';

Future<bool> hasCompleted() async => html.window.localStorage[_key] == 'true';

Future<void> markCompleted() async {
  html.window.localStorage[_key] = 'true';
}
