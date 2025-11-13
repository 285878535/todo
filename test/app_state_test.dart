import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/state/app_state.dart';
import 'package:todo/models/task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('app state add and rest seconds', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppState();
    await s.init();
    final countBefore = s.tasks.length;
    await s.addTask(name: '测试', mode: TimerMode.stopwatch);
    expect(s.tasks.length, countBefore + 1);
    await s.setRestSeconds(120);
    expect(s.restSeconds, 120);
  });
}
