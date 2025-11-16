import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../utils/storage.dart';
import '../models/record.dart';
import '../utils/recurring_task_manager.dart';
import '../services/notification_service.dart';
import '../theme.dart';

class AppState extends ChangeNotifier {
  final _uuid = const Uuid();
  List<Task> _tasks = [];
  String? _activeTaskId;
  Timer? _timer;
  bool _paused = false;
  int _restSeconds = 300;
  bool _resting = false;
  Timer? _restTimer;
  List<Record> _records = [];
  Timer? _midnightTimer;
  int _dailyGoalSeconds = 3600;
  AppTheme _currentTheme = AppTheme.light;
  String? _backgroundImagePath;

  List<Task> get tasks => List.unmodifiable(_tasks);
  String? get activeTaskId => _activeTaskId;
  bool get paused => _paused;
  int get restSeconds => _restSeconds;
  bool get resting => _resting;
  List<Record> get records => List.unmodifiable(_records);
  int get dailyGoalSeconds => _dailyGoalSeconds;
  AppTheme get currentTheme => _currentTheme;
  String? get backgroundImagePath => _backgroundImagePath;

  Future<void> init() async {
    _tasks = await Storage.loadTasks();
    _restSeconds = await Storage.loadRestSeconds();
    _records = await Storage.loadRecords();
    _dailyGoalSeconds = await Storage.loadDailyGoalSeconds();
    _currentTheme = await Storage.loadTheme();
    _backgroundImagePath = await Storage.loadBackgroundImage();
    
    // Initialize notifications
    await NotificationService.initialize();
    
    await _ensureDailyReset();
    _scheduleMidnightReset();
    
    // 不再自动创建示例任务，让用户通过新手引导学习如何创建任务
    // final isFirstLaunch = await Storage.isFirstLaunch();
    // if (isFirstLaunch && _tasks.isEmpty) {
    //   await _createSampleTasks();
    //   await Storage.setNotFirstLaunch();
    // }
    
    notifyListeners();
  }

  Future<void> setRestSeconds(int seconds) async {
    _restSeconds = seconds;
    await Storage.saveRestSeconds(seconds);
    notifyListeners();
  }

  Future<void> addTask({
    required String name,
    String? note,
    required TimerMode mode,
    int targetSeconds = 0,
    Priority priority = Priority.medium,
    List<Tag> tags = const [],
    DateTime? dueDate,
    bool isRecurring = false,
    String? recurringPattern,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      name: name,
      note: note,
      mode: mode,
      targetSeconds: targetSeconds,
      priority: priority,
      tags: tags,
      dueDate: dueDate,
      isRecurring: isRecurring,
      recurringPattern: recurringPattern,
    );
    _tasks = [..._tasks, task];
    await Storage.saveTasks(_tasks);
    
    // Schedule reminder notification if due date is set
    if (dueDate != null) {
      final reminderTime = dueDate.subtract(const Duration(hours: 1));
      if (reminderTime.isAfter(DateTime.now())) {
        NotificationService.scheduleTaskReminder(name, reminderTime);
      }
    }
    
    notifyListeners();
  }

  Future<void> updateTask(Task updated) async {
    _tasks = _tasks.map((t) => t.id == updated.id ? updated : t).toList();
    await Storage.saveTasks(_tasks);
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    final wasActive = _activeTaskId == id;
    _tasks = _tasks.where((t) => t.id != id).toList();
    if (wasActive) stopTask();
    await Storage.saveTasks(_tasks);
    notifyListeners();
  }

  Task? get activeTask {
    try {
      return _tasks.firstWhere((t) => t.id == _activeTaskId);
    } catch (_) {
      return null;
    }
  }

  void startTask(String id) {
    _activeTaskId = id;
    _paused = false;
    _resting = false;
    _restTimer?.cancel();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void pauseTask() {
    _paused = true;
    notifyListeners();
  }

  void resumeTask() {
    _paused = false;
    notifyListeners();
  }

  void stopTask() {
    _timer?.cancel();
    _activeTaskId = null;
    _paused = false;
    notifyListeners();
  }

  void _tick() {
    if (_paused || _activeTaskId == null) return;
    final index = _tasks.indexWhere((t) => t.id == _activeTaskId);
    if (index == -1) return;
    final t = _tasks[index];
    final nextElapsed = t.elapsedSeconds + 1;
    var updated = t.copyWith(elapsedSeconds: nextElapsed);
    if (t.mode == TimerMode.countdown && nextElapsed >= t.targetSeconds) {
      updated = updated.copyWith(completed: true, lastCompletedAt: DateTime.now());
      _tasks[index] = updated;
      _completeAndRest();
    } else {
      _tasks[index] = updated;
    }
    
    // Check if daily goal is reached
    final previousTotal = todayTotalSeconds;
    if (previousTotal < _dailyGoalSeconds && previousTotal + 1 >= _dailyGoalSeconds) {
      // Daily goal reached!
      NotificationService.showDailyGoalNotification(_dailyGoalSeconds, _dailyGoalSeconds);
    }
    
    notifyListeners();
  }

  void manualCompleteActive() {
    if (_activeTaskId == null) return;
    final index = _tasks.indexWhere((t) => t.id == _activeTaskId);
    if (index == -1) return;
    final t = _tasks[index];
    final updated = t.copyWith(completed: true, lastCompletedAt: DateTime.now());
    _tasks[index] = updated;
    _completeAndRest();
    notifyListeners();
  }

  void _completeAndRest() {
    final completedTaskId = _activeTaskId!;
    _timer?.cancel();
    _updateStreakFor(completedTaskId);
    _appendRecordFor(completedTaskId);
    
    // 对于重复任务，不要立即创建新任务
    // 而是等到0点后通过 _ensureDailyReset() 重新生成
    // 这样可以确保重复任务在第二天才出现
    
    // Show completion notification
    final completedTask = _tasks.firstWhere((t) => t.id == completedTaskId);
    NotificationService.showTaskCompletionNotification(completedTask.name);
    
    _activeTaskId = null;
    _paused = false;
    _resting = true;
    var remaining = _restSeconds;
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining -= 1;
      if (remaining <= 0) {
        timer.cancel();
        _resting = false;
        // Show rest end notification
        NotificationService.showRestEndNotification();
      }
      notifyListeners();
    });
    Storage.saveTasks(_tasks);
    Storage.saveRecords(_records);
  }

  void skipRest() {
    _restTimer?.cancel();
    _resting = false;
    notifyListeners();
  }

  void _updateStreakFor(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final t = _tasks[index];
    final now = DateTime.now();
    int streak = t.streak;
    if (t.lastCompletedAt != null) {
      final last = t.lastCompletedAt!;
      final diffDays = DateTime(now.year, now.month, now.day)
          .difference(DateTime(last.year, last.month, last.day))
          .inDays;
      if (diffDays == 1) {
        streak += 1;
      } else if (diffDays > 1) {
        streak = 1;
      }
    } else {
      streak = 1;
    }
    _tasks[index] = t.copyWith(streak: streak, lastCompletedAt: now);
  }

  void _appendRecordFor(String id) {
    final t = _tasks.firstWhere((e) => e.id == id);
    final spent = t.mode == TimerMode.countdown ? t.targetSeconds : t.elapsedSeconds;
    _records = [
      ..._records,
      Record(taskId: t.id, taskName: t.name, seconds: spent, at: DateTime.now()),
    ];
  }

  Future<void> _ensureDailyReset() async {
    final last = await Storage.loadLastResetDate();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (last == null || last.isBefore(todayDate)) {
      // Process recurring tasks before the daily reset
      _tasks = RecurringTaskManager.processRecurringTasks(_tasks);
      
      // Reset daily progress for non-recurring tasks
      _tasks = _tasks
          .map((t) => t.isRecurring ? t : t.copyWith(elapsedSeconds: 0, completed: false))
          .toList();
      
      await Storage.saveTasks(_tasks);
      await Storage.saveLastResetDate(todayDate);
    }
  }

  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);
    _midnightTimer = Timer(duration, () async {
      await _ensureDailyReset();
      _scheduleMidnightReset();
      notifyListeners();
    });
  }

  int get todayTotalSeconds {
    final now = DateTime.now();
    final dateKey = DateTime(now.year, now.month, now.day);
    return _records
        .where((r) {
          final k = DateTime(r.at.year, r.at.month, r.at.day);
          return k == dateKey;
        })
        .fold(0, (sum, r) => sum + r.seconds);
  }

  int get todayCompletions {
    final now = DateTime.now();
    final dateKey = DateTime(now.year, now.month, now.day);
    return _records.where((r) => DateTime(r.at.year, r.at.month, r.at.day) == dateKey).length;
  }

  List<int> get weeklyTotals {
    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day - (6 - i)));
    return days
        .map((d) => _records
            .where((r) => DateTime(r.at.year, r.at.month, r.at.day) == d)
            .fold(0, (sum, r) => sum + r.seconds))
        .toList();
  }

  Future<void> setDailyGoalSeconds(int seconds) async {
    _dailyGoalSeconds = seconds;
    await Storage.saveDailyGoalSeconds(seconds);
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    await Storage.saveTheme(theme);
    notifyListeners();
  }

  Future<void> setBackgroundImage(String? path) async {
    _backgroundImagePath = path;
    await Storage.saveBackgroundImage(path);
    notifyListeners();
  }
}
