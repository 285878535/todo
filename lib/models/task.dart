import 'dart:convert';
import 'package:flutter/material.dart';

enum TimerMode { countdown, stopwatch }
enum Priority { low, medium, high, urgent }
enum Tag { 
  work, study, exercise, health, hobby, social, 
  shopping, cleaning, finance, planning, creative, 
  rest, learning, family, personal, other 
}

class Task {
  final String id;
  final String name;
  final String? note;
  final TimerMode mode;
  final int targetSeconds;
  final int elapsedSeconds;
  final bool completed;
  final DateTime? lastCompletedAt;
  final int streak;
  final Priority priority;
  final List<Tag> tags;
  final DateTime? dueDate;
  final bool isRecurring;
  final String? recurringPattern;

  Task({
    required this.id,
    required this.name,
    this.note,
    required this.mode,
    this.targetSeconds = 0,
    this.elapsedSeconds = 0,
    this.completed = false,
    this.lastCompletedAt,
    this.streak = 0,
    this.priority = Priority.medium,
    this.tags = const [],
    this.dueDate,
    this.isRecurring = false,
    this.recurringPattern,
  });

  Task copyWith({
    String? id,
    String? name,
    String? note,
    TimerMode? mode,
    int? targetSeconds,
    int? elapsedSeconds,
    bool? completed,
    DateTime? lastCompletedAt,
    int? streak,
    Priority? priority,
    List<Tag>? tags,
    DateTime? dueDate,
    bool? isRecurring,
    String? recurringPattern,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      mode: mode ?? this.mode,
      targetSeconds: targetSeconds ?? this.targetSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      completed: completed ?? this.completed,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      streak: streak ?? this.streak,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      dueDate: dueDate ?? this.dueDate,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
    );
  }

  int get remainingSeconds => mode == TimerMode.countdown
      ? (targetSeconds - elapsedSeconds).clamp(0, targetSeconds)
      : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'note': note,
      'mode': mode.name,
      'targetSeconds': targetSeconds,
      'elapsedSeconds': elapsedSeconds,
      'completed': completed,
      'lastCompletedAt': lastCompletedAt?.millisecondsSinceEpoch,
      'streak': streak,
      'priority': priority.name,
      'tags': tags.map((tag) => tag.name).toList(),
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      name: map['name'] as String,
      note: map['note'] as String?,
      mode: (map['mode'] as String) == TimerMode.countdown.name
          ? TimerMode.countdown
          : TimerMode.stopwatch,
      targetSeconds: map['targetSeconds'] as int? ?? 0,
      elapsedSeconds: map['elapsedSeconds'] as int? ?? 0,
      completed: map['completed'] as bool? ?? false,
      lastCompletedAt: map['lastCompletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['lastCompletedAt'] as int,
            )
          : null,
      streak: map['streak'] as int? ?? 0,
      priority: Priority.values.firstWhere(
        (p) => p.name == (map['priority'] as String?),
        orElse: () => Priority.medium,
      ),
      tags: (map['tags'] as List<dynamic>?)
              ?.map((tag) => Tag.values.firstWhere(
                    (t) => t.name == tag,
                    orElse: () => Tag.other,
                  ))
              .toList() ??
          [],
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int)
          : null,
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurringPattern: map['recurringPattern'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Task.fromJson(String source) =>
      Task.fromMap(jsonDecode(source) as Map<String, dynamic>);

  // Helper methods for priority
  Color getPriorityColor() {
    switch (priority) {
      case Priority.urgent:
        return const Color(0xFFFF5252);
      case Priority.high:
        return const Color(0xFFFF9800);
      case Priority.medium:
        return const Color(0xFF4CAF50);
      case Priority.low:
        return const Color(0xFF2196F3);
    }
  }

  IconData getPriorityIcon() {
    switch (priority) {
      case Priority.urgent:
        return Icons.error_outline;
      case Priority.high:
        return Icons.keyboard_arrow_up;
      case Priority.medium:
        return Icons.remove;
      case Priority.low:
        return Icons.keyboard_arrow_down;
    }
  }

  String getPriorityLabel() {
    switch (priority) {
      case Priority.urgent:
        return '紧急';
      case Priority.high:
        return '高';
      case Priority.medium:
        return '中';
      case Priority.low:
        return '低';
    }
  }

  // Helper methods for tags
  IconData getTagIcon(Tag tag) {
    switch (tag) {
      case Tag.work:
        return Icons.work_outline;
      case Tag.study:
        return Icons.school_outlined;
      case Tag.exercise:
        return Icons.fitness_center_outlined;
      case Tag.health:
        return Icons.health_and_safety_outlined;
      case Tag.hobby:
        return Icons.palette_outlined;
      case Tag.social:
        return Icons.people_outline;
      case Tag.shopping:
        return Icons.shopping_cart_outlined;
      case Tag.cleaning:
        return Icons.cleaning_services_outlined;
      case Tag.finance:
        return Icons.account_balance_wallet_outlined;
      case Tag.planning:
        return Icons.event_note_outlined;
      case Tag.creative:
        return Icons.lightbulb_outline;
      case Tag.rest:
        return Icons.bedtime_outlined;
      case Tag.learning:
        return Icons.menu_book_outlined;
      case Tag.family:
        return Icons.home_outlined;
      case Tag.personal:
        return Icons.person_outline;
      case Tag.other:
        return Icons.label_outline;
    }
  }

  String getTagLabel(Tag tag) {
    switch (tag) {
      case Tag.work:
        return '工作';
      case Tag.study:
        return '学习';
      case Tag.exercise:
        return '运动';
      case Tag.health:
        return '健康';
      case Tag.hobby:
        return '爱好';
      case Tag.social:
        return '社交';
      case Tag.shopping:
        return '购物';
      case Tag.cleaning:
        return '清洁';
      case Tag.finance:
        return '财务';
      case Tag.planning:
        return '计划';
      case Tag.creative:
        return '创意';
      case Tag.rest:
        return '休息';
      case Tag.learning:
        return '学习';
      case Tag.family:
        return '家庭';
      case Tag.personal:
        return '个人';
      case Tag.other:
        return '其他';
    }
  }

  // Check if task is overdue
  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && !completed;
  }

  // Get days until due
  int? get daysUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final difference = dueDate!.difference(now).inDays;
    return difference >= 0 ? difference : 0;
  }
}

// Extension methods for task filtering and sorting
extension TaskListExtensions on List<Task> {
  List<Task> filterByPriority(Priority priority) {
    return where((task) => task.priority == priority).toList();
  }

  List<Task> filterByTag(Tag tag) {
    return where((task) => task.tags.contains(tag)).toList();
  }

  List<Task> filterByCompletion(bool completed) {
    return where((task) => task.completed == completed).toList();
  }

  List<Task> filterByOverdue() {
    return where((task) => task.isOverdue).toList();
  }

  List<Task> filterByDueDate(DateTime date) {
    return where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == date.year &&
             task.dueDate!.month == date.month &&
             task.dueDate!.day == date.day;
    }).toList();
  }

  List<Task> sortByPriority() {
    final sorted = List<Task>.from(this);
    sorted.sort((a, b) {
      final priorityOrder = {Priority.urgent: 4, Priority.high: 3, Priority.medium: 2, Priority.low: 1};
      return priorityOrder[b.priority]!.compareTo(priorityOrder[a.priority]!);
    });
    return sorted;
  }

  List<Task> sortByDueDate() {
    final sorted = List<Task>.from(this);
    sorted.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return sorted;
  }
}
