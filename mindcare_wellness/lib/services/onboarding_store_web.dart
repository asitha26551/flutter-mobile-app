import 'package:web/web.dart' as web;

const _key = 'mindcare.onboarding.completed';

Future<bool> hasCompleted() async =>
    web.window.localStorage.getItem(_key) == 'true';

Future<void> markCompleted() async {
  web.window.localStorage.setItem(_key, 'true');
}
