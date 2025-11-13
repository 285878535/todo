
import '../models/task.dart';

enum RecurringPattern {
  daily,
  weekly,
  monthly,
  weekdays, // Monday to Friday
  weekends, // Saturday and Sunday
  custom,
}

class RecurringTaskManager {
  static Task createRecurringInstance(Task original, DateTime now) {
    return Task(
      id: original.id, // This will be replaced with a new ID in AppState
      name: original.name,
      note: original.note,
      mode: original.mode,
      targetSeconds: original.targetSeconds,
      elapsedSeconds: 0, // Reset elapsed time
      completed: false, // Reset completion status
      lastCompletedAt: null, // Reset last completion
      streak: original.streak, // Keep the streak
      priority: original.priority,
      tags: original.tags,
      dueDate: _calculateNextDueDate(original.dueDate, original.recurringPattern!),
      isRecurring: true,
      recurringPattern: original.recurringPattern,
    );
  }

  static Task _createRecurringInstance(Task original, DateTime now) {
    return Task(
      id: original.id, // This will be replaced with a new ID in AppState
      name: original.name,
      note: original.note,
      mode: original.mode,
      targetSeconds: original.targetSeconds,
      elapsedSeconds: 0, // Reset elapsed time
      completed: false, // Reset completion status
      lastCompletedAt: null, // Reset last completion
      streak: original.streak, // Keep the streak
      priority: original.priority,
      tags: original.tags,
      dueDate: _calculateNextDueDate(original.dueDate, original.recurringPattern!),
      isRecurring: true,
      recurringPattern: original.recurringPattern,
    );
  }

  static List<Task> processRecurringTasks(List<Task> tasks) {
    final now = DateTime.now();
    final updatedTasks = <Task>[];
    
    for (final task in tasks) {
      if (task.isRecurring && task.recurringPattern != null) {
        final shouldRecreate = _shouldRecreateTask(task, now);
        if (shouldRecreate) {
          // Create a new instance of the recurring task
          final newTask = _createRecurringInstance(task, now);
          updatedTasks.add(newTask);
        } else {
          updatedTasks.add(task);
        }
      } else {
        updatedTasks.add(task);
      }
    }
    
    return updatedTasks;
  }

  static bool _shouldRecreateTask(Task task, DateTime now) {
    if (!task.isRecurring || task.recurringPattern == null) return false;
    
    // If task is completed and was completed yesterday or earlier
    if (task.completed && task.lastCompletedAt != null) {
      final lastCompleted = task.lastCompletedAt!;
      final daysSinceCompletion = now.difference(lastCompleted).inDays;
      
      if (daysSinceCompletion > 0) {
        return _shouldCreateForDate(task.recurringPattern!, now);
      }
    }
    
    return false;
  }

  static bool _shouldCreateForDate(String pattern, DateTime date) {
    switch (pattern) {
      case 'daily':
        return true;
      case 'weekly':
        return date.weekday == DateTime.monday;
      case 'monthly':
        return date.day == 1;
      case 'weekdays':
        return date.weekday >= DateTime.monday && date.weekday <= DateTime.friday;
      case 'weekends':
        return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      case 'custom':
        // For custom patterns, we'd need more complex logic
        return true;
      default:
        return false;
    }
  }

  static DateTime? _calculateNextDueDate(DateTime? originalDueDate, String pattern) {
    if (originalDueDate == null) return null;
    
    final now = DateTime.now();
    
    switch (pattern) {
      case 'daily':
        return now.add(const Duration(days: 1));
      case 'weekly':
        return now.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(now.year, now.month + 1, originalDueDate.day);
      case 'weekdays':
        // Next weekday
        var nextDay = now.add(const Duration(days: 1));
        while (nextDay.weekday == DateTime.saturday || nextDay.weekday == DateTime.sunday) {
          nextDay = nextDay.add(const Duration(days: 1));
        }
        return nextDay;
      case 'weekends':
        // Next weekend day
        var nextDay = now.add(const Duration(days: 1));
        while (nextDay.weekday != DateTime.saturday && nextDay.weekday != DateTime.sunday) {
          nextDay = nextDay.add(const Duration(days: 1));
        }
        return nextDay;
      default:
        return now.add(const Duration(days: 1));
    }
  }

  static String getPatternDescription(String pattern) {
    switch (pattern) {
      case 'daily':
        return '每天';
      case 'weekly':
        return '每周';
      case 'monthly':
        return '每月';
      case 'weekdays':
        return '工作日';
      case 'weekends':
        return '周末';
      case 'custom':
        return '自定义';
      default:
        return '未知';
    }
  }

  static String getPatternIcon(String pattern) {
    switch (pattern) {
      case 'daily':
        return '📅';
      case 'weekly':
        return '📆';
      case 'monthly':
        return '🗓️';
      case 'weekdays':
        return '💼';
      case 'weekends':
        return '🏖️';
      case 'custom':
        return '⚙️';
      default:
        return '❓';
    }
  }

  static List<String> getAvailablePatterns() {
    return ['daily', 'weekly', 'monthly', 'weekdays', 'weekends'];
  }

  static DateTime? getNextOccurrence(String pattern, DateTime? currentDueDate) {
    final now = DateTime.now();
    
    switch (pattern) {
      case 'daily':
        return now.add(const Duration(days: 1));
      case 'weekly':
        return now.add(const Duration(days: 7));
      case 'monthly':
        if (currentDueDate != null) {
          return DateTime(now.year, now.month + 1, currentDueDate.day);
        }
        return DateTime(now.year, now.month + 1, 1);
      case 'weekdays':
        var nextDay = now.add(const Duration(days: 1));
        while (nextDay.weekday == DateTime.saturday || nextDay.weekday == DateTime.sunday) {
          nextDay = nextDay.add(const Duration(days: 1));
        }
        return nextDay;
      case 'weekends':
        var nextDay = now.add(const Duration(days: 1));
        while (nextDay.weekday != DateTime.saturday && nextDay.weekday != DateTime.sunday) {
          nextDay = nextDay.add(const Duration(days: 1));
        }
        return nextDay;
      default:
        return null;
    }
  }

  static bool shouldShowToday(String pattern) {
    final now = DateTime.now();
    
    switch (pattern) {
      case 'daily':
        return true;
      case 'weekly':
        return now.weekday == DateTime.monday;
      case 'monthly':
        return now.day == 1;
      case 'weekdays':
        return now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
      case 'weekends':
        return now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
      default:
        return false;
    }
  }
}