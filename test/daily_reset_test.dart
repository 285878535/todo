import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/state/app_state.dart';
import 'package:todo/models/task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('daily reset clears progress', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    SharedPreferences.setMockInitialValues({
      'tasks': [
        Task(id: '1', name: '倒计时', mode: TimerMode.countdown, targetSeconds: 60, elapsedSeconds: 30, completed: true)
            .toJson(),
      ],
      'lastResetDate': DateTime(yesterday.year, yesterday.month, yesterday.day).millisecondsSinceEpoch,
    });
    final s = AppState();
    await s.init();
    expect(s.tasks.first.elapsedSeconds, 0);
    expect(s.tasks.first.completed, false);
  });
}
