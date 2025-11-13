import 'package:flutter_test/flutter_test.dart';
import 'package:todo/models/task.dart';

void main() {
  test('task serialization', () {
    final t = Task(id: '1', name: 'a', mode: TimerMode.countdown, targetSeconds: 60, elapsedSeconds: 10);
    final json = t.toJson();
    final t2 = Task.fromJson(json);
    expect(t2.id, '1');
    expect(t2.name, 'a');
    expect(t2.mode, TimerMode.countdown);
    expect(t2.targetSeconds, 60);
    expect(t2.elapsedSeconds, 10);
    expect(t2.remainingSeconds, 50);
  });
}
