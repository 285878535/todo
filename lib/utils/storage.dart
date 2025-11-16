import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';
import '../models/record.dart';
import '../theme.dart';

class Storage {
  static const _tasksKey = 'tasks';
  static const _restSecondsKey = 'restSeconds';
  static const _recordsKey = 'records';
  static const _lastResetKey = 'lastResetDate';
  static const _dailyGoalKey = 'dailyGoalSeconds';
  static const _themeKey = 'appTheme';
  static const _backgroundImageKey = 'backgroundImagePath';
  static const _isFirstLaunchKey = 'isFirstLaunch';

  static Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_tasksKey) ?? [];
    return data.map((e) => Task.fromJson(e)).toList();
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_tasksKey, tasks.map((e) => e.toJson()).toList());
  }

  static Future<int> loadRestSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_restSecondsKey) ?? 300;
  }

  static Future<void> saveRestSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_restSecondsKey, seconds);
  }

  static Future<List<Record>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_recordsKey) ?? [];
    return data.map((e) => Record.fromMap(jsonDecode(e) as Map<String, dynamic>)).toList();
  }

  static Future<void> saveRecords(List<Record> records) async {
    final prefs = await SharedPreferences.getInstance();
    final list = records.map((r) => jsonEncode(r.toMap())).toList();
    await prefs.setStringList(_recordsKey, list);
  }

  static Future<DateTime?> loadLastResetDate() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastResetKey);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  static Future<void> saveLastResetDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastResetKey, DateTime(date.year, date.month, date.day).millisecondsSinceEpoch);
  }

  static Future<int> loadDailyGoalSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyGoalKey) ?? 3600;
  }

  static Future<void> saveDailyGoalSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyGoalKey, seconds);
  }

  static Future<AppTheme> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    return AppTheme.values[themeIndex.clamp(0, AppTheme.values.length - 1)];
  }

  static Future<void> saveTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }

  static Future<String?> loadBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backgroundImageKey);
  }

  static Future<void> saveBackgroundImage(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_backgroundImageKey);
    } else {
      await prefs.setString(_backgroundImageKey, path);
    }
  }

  // 检查是否是首次启动
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }

  // 标记已经不是首次启动
  static Future<void> setNotFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, false);
  }
}
