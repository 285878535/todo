import '../models/task.dart';

class NlpParser {
  static TaskParseResult parse(String input) {
    final normalized = input.toLowerCase().trim();
    
    // Extract time information
    final timeResult = _extractTime(normalized);
    
    // Extract priority information
    final priority = _extractPriority(normalized);
    
    // Extract tags
    final tags = _extractTags(normalized);
    
    // Extract due date
    final dueDate = _extractDueDate(normalized);
    
    // Extract task name (clean up the input)
    final taskName = _extractTaskName(normalized);
    
    // Determine timer mode based on keywords
    final mode = _determineMode(normalized);
    
    return TaskParseResult(
      name: taskName,
      mode: mode,
      targetSeconds: timeResult.seconds,
      priority: priority,
      tags: tags,
      dueDate: dueDate,
      confidence: _calculateConfidence(input, taskName, timeResult),
    );
  }

  static TimeResult _extractTime(String input) {
    // Common time patterns
    final patterns = [
      // 半小时, 半个小时
      RegExp(r'半\s*[个]?\s*(小时|hour|h)', caseSensitive: false),
      // 半分钟
      RegExp(r'半\s*(分钟|min|分钟|分)', caseSensitive: false),
      // 25 minutes, 30 mins, 45min
      RegExp(r'(\d+)\s*(分钟|min|分钟|分)', caseSensitive: false),
      // 1 hour, 2 hours, 1.5 hours (excluding time points like "6点")
      RegExp(r'([一二三四五六七八九十\d]+(?:\.\d+)?)\s*[个]?\s*(小时|hour|h)(?!.*点)', caseSensitive: false),
      // 1500 seconds
      RegExp(r'(\d+)\s*(秒|second|秒|s)', caseSensitive: false),
      // Pomodoro patterns
      RegExp(r'(番茄|pomodoro|番茄钟)', caseSensitive: false),
      // Quick patterns
      RegExp(r'(快速|quick|5分钟)', caseSensitive: false),
      // Long patterns
      RegExp(r'(长|long|深度|deep)', caseSensitive: false),
    ];

    int totalSeconds = 0;
    bool hasTime = false;

    // Check for 半小时 (30 minutes)
    if (patterns[0].hasMatch(input)) {
      totalSeconds += 1800; // 30 minutes
      hasTime = true;
    }

    // Check for 半分钟 (30 seconds)
    if (patterns[1].hasMatch(input)) {
      totalSeconds += 30; // 30 seconds
      hasTime = true;
    }

    // Check for pomodoro (25 minutes)
    if (patterns[5].hasMatch(input)) {
      totalSeconds += 1500; // 25 minutes
      hasTime = true;
    }

    // Check for quick patterns (5 minutes)
    if (patterns[6].hasMatch(input)) {
      totalSeconds += 300; // 5 minutes
      hasTime = true;
    }

    // Check for long patterns (45 minutes)
    if (patterns[7].hasMatch(input)) {
      totalSeconds += 2700; // 45 minutes
      hasTime = true;
    }

    // Check for explicit minutes
    final minuteMatch = patterns[2].firstMatch(input);
    if (minuteMatch != null) {
      final minutes = int.parse(minuteMatch.group(1)!);
      totalSeconds += minutes * 60;
      hasTime = true;
    }

    // Check for hours (supporting Chinese numbers)
    final hourMatch = patterns[3].firstMatch(input);
    if (hourMatch != null) {
      final hourStr = hourMatch.group(1)!;
      final hours = _parseChineseNumber(hourStr);
      totalSeconds += (hours * 3600).round();
      hasTime = true;
    }

    // Check for seconds
    final secondMatch = patterns[4].firstMatch(input);
    if (secondMatch != null) {
      final seconds = int.parse(secondMatch.group(1)!);
      totalSeconds += seconds;
      hasTime = true;
    }

    return TimeResult(seconds: totalSeconds, hasTime: hasTime);
  }

  // Helper function to parse Chinese numbers
  static double _parseChineseNumber(String input) {
    final chineseNumbers = {
      '零': 0, '一': 1, '二': 2, '三': 3, '四': 4,
      '五': 5, '六': 6, '七': 7, '八': 8, '九': 9, '十': 10,
      '两': 2, '半': 0.5,
    };
    
    // Try to parse as Arabic number first
    final arabicNumber = double.tryParse(input);
    if (arabicNumber != null) {
      return arabicNumber;
    }
    
    // Handle Chinese numbers
    if (chineseNumbers.containsKey(input)) {
      return chineseNumbers[input]!.toDouble();
    }
    
    // Handle compound numbers like "一个半"
    if (input.contains('半')) {
      double base = 0;
      for (final entry in chineseNumbers.entries) {
        if (input.contains(entry.key) && entry.key != '半') {
          base = entry.value.toDouble();
          break;
        }
      }
      return base + 0.5;
    }
    
    // Default to 1 if cannot parse
    return 1.0;
  }

  static Priority _extractPriority(String input) {
    final urgentPatterns = [
      '紧急', 'urgent', '重要', 'important', '马上', '立刻', '立即',
      'asap', 'urgent', 'critical', 'priority', '优先'
    ];
    
    final highPatterns = [
      '高', 'high', '重要', 'important', '优先', 'priority'
    ];
    
    final lowPatterns = [
      '低', 'low', '次要', 'minor', '简单', 'simple', '轻松', 'easy'
    ];

    for (final pattern in urgentPatterns) {
      if (input.contains(pattern.toLowerCase())) {
        return Priority.urgent;
      }
    }

    for (final pattern in highPatterns) {
      if (input.contains(pattern.toLowerCase())) {
        return Priority.high;
      }
    }

    for (final pattern in lowPatterns) {
      if (input.contains(pattern.toLowerCase())) {
        return Priority.low;
      }
    }

    return Priority.medium;
  }

  static List<Tag> _extractTags(String input) {
    final tags = <Tag>[];
    
    final tagMappings = {
      // Work related
      '工作': Tag.work, 'work': Tag.work, '办公': Tag.work, '任务': Tag.work,
      '项目': Tag.work, '会议': Tag.work, '报告': Tag.work,
      
      // Study related
      '学习': Tag.study, 'study': Tag.study, '读书': Tag.study, '阅读': Tag.study,
      '复习': Tag.study, '预习': Tag.study, '作业': Tag.study, '课程': Tag.study,
      
      // Exercise
      '运动': Tag.exercise, '锻炼': Tag.exercise, '健身': Tag.exercise,
      '跑步': Tag.exercise, '游泳': Tag.exercise, '瑜伽': Tag.exercise,
      
      // Health
      '健康': Tag.health, 'health': Tag.health, '饮食': Tag.health,
      '睡眠': Tag.health, '休息': Tag.rest, '放松': Tag.rest,
      
      // Hobby
      '爱好': Tag.hobby, 'hobby': Tag.hobby, '兴趣': Tag.hobby,
      '画画': Tag.hobby, '音乐': Tag.hobby, '游戏': Tag.hobby,
      
      // Social
      '社交': Tag.social, 'social': Tag.social, '朋友': Tag.social,
      '家人': Tag.family, 'family': Tag.family, '家庭': Tag.family,
      
      // Shopping
      '购物': Tag.shopping, 'shop': Tag.shopping, '买': Tag.shopping,
      '采购': Tag.shopping, '超市': Tag.shopping,
      
      // Cleaning
      '清洁': Tag.cleaning, 'clean': Tag.cleaning, '打扫': Tag.cleaning,
      '整理': Tag.cleaning, '收纳': Tag.cleaning,
      
      // Finance
      '财务': Tag.finance, 'finance': Tag.finance, '钱': Tag.finance,
      '预算': Tag.finance, '投资': Tag.finance, '理财': Tag.finance,
      
      // Planning
      '计划': Tag.planning, 'plan': Tag.planning, '规划': Tag.planning,
      '安排': Tag.planning, '日程': Tag.planning,
      
      // Creative
      '创意': Tag.creative, 'creative': Tag.creative, '创作': Tag.creative,
      '写作': Tag.creative, '设计': Tag.creative,
      
      // Learning
      '技能': Tag.learning, 'skill': Tag.learning, '培训': Tag.learning,
      '练习': Tag.learning, '训练': Tag.learning,
      
      // Personal
      '个人': Tag.personal, 'personal': Tag.personal, '私事': Tag.personal,
      '自己': Tag.personal, '私人': Tag.personal,
    };

    for (final entry in tagMappings.entries) {
      if (input.contains(entry.key.toLowerCase())) {
        tags.add(entry.value);
      }
    }

    return tags.toSet().toList(); // Remove duplicates
  }

  static DateTime? _extractDueDate(String input) {
    final now = DateTime.now();
    DateTime? baseDate;
    
    // Today patterns
    final todayPatterns = ['今天', 'today', '今日'];
    for (final pattern in todayPatterns) {
      if (input.contains(pattern)) {
        baseDate = DateTime(now.year, now.month, now.day);
        break;
      }
    }
    
    // Tomorrow patterns
    final tomorrowPatterns = ['明天', 'tomorrow', '明日'];
    for (final pattern in tomorrowPatterns) {
      if (input.contains(pattern)) {
        final tomorrow = now.add(const Duration(days: 1));
        baseDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
        break;
      }
    }
    
    // This week patterns
    final weekPatterns = ['本周', 'this week', '这周'];
    for (final pattern in weekPatterns) {
      if (input.contains(pattern)) {
        final endOfWeek = now.add(Duration(days: 7 - now.weekday));
        baseDate = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
        break;
      }
    }
    
    // This month patterns
    final monthPatterns = ['本月', 'this month', '这个月'];
    for (final pattern in monthPatterns) {
      if (input.contains(pattern)) {
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        baseDate = endOfMonth;
        break;
      }
    }
    
    // Specific date patterns (simplified)
    if (baseDate == null) {
      final datePattern = RegExp(r'(\d{1,2})[月/-](\d{1,2})[日号]?');
      final dateMatch = datePattern.firstMatch(input);
      if (dateMatch != null) {
        final month = int.parse(dateMatch.group(1)!);
        final day = int.parse(dateMatch.group(2)!);
        baseDate = DateTime(now.year, month, day);
      }
    }
    
    // If we have a base date, try to extract time
    if (baseDate != null) {
      final timeInfo = _extractTimePoint(input);
      if (timeInfo != null) {
        return DateTime(
          baseDate.year, 
          baseDate.month, 
          baseDate.day,
          timeInfo['hour']!,
          timeInfo['minute']!,
        );
      }
    }
    
    return baseDate;
  }
  
  // Extract time point (e.g., "下午3点", "18:30")
  static Map<String, int>? _extractTimePoint(String input) {
    // Match patterns like "下午3点", "上午10点半", "晚上8点"
    final timePatterns = [
      RegExp(r'(上午|早上|morning)\s*([一二三四五六七八九十\d]+)\s*点\s*(半)?'),
      RegExp(r'(下午|afternoon)\s*([一二三四五六七八九十\d]+)\s*点\s*(半)?'),
      RegExp(r'(晚上|evening|夜里|night)\s*([一二三四五六七八九十\d]+)\s*点\s*(半)?'),
      RegExp(r'(\d{1,2})\s*[:：点]\s*(\d{0,2})\s*(分)?'),
    ];
    
    for (final pattern in timePatterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        // Pattern with time of day (上午/下午/晚上)
        if (pattern == timePatterns[0] || pattern == timePatterns[1] || pattern == timePatterns[2]) {
          final timeOfDay = match.group(1)!;
          final hourStr = match.group(2)!;
          final hasHalf = match.group(3) != null;
          
          int hour = _parseChineseNumber(hourStr).toInt();
          
          // Convert to 24-hour format
          if (timeOfDay == '下午' || timeOfDay == 'afternoon') {
            if (hour < 12) hour += 12;
          } else if (timeOfDay == '晚上' || timeOfDay == 'evening' || timeOfDay == '夜里' || timeOfDay == 'night') {
            if (hour < 12) hour += 12;
            if (hour == 12) hour = 0; // 晚上12点 = 0点
          }
          
          final minute = hasHalf ? 30 : 0;
          return {'hour': hour, 'minute': minute};
        }
        // Pattern with numeric time
        else if (pattern == timePatterns[3]) {
          final hour = int.parse(match.group(1)!);
          final minuteStr = match.group(2);
          final minute = minuteStr != null && minuteStr.isNotEmpty ? int.parse(minuteStr) : 0;
          return {'hour': hour, 'minute': minute};
        }
      }
    }
    
    return null;
  }

  static TimerMode _determineMode(String input) {
    // Countdown patterns
    final countdownPatterns = [
      '番茄', 'pomodoro', '番茄钟', '倒计时', 'countdown', '定时', '限时',
      '分钟', 'min', '小时', 'hour', '25分', '30分', '45分', '半小时', '半分钟'
    ];
    
    for (final pattern in countdownPatterns) {
      if (input.contains(pattern.toLowerCase())) {
        return TimerMode.countdown;
      }
    }
    
    // Stopwatch patterns
    final stopwatchPatterns = [
      '计时', 'stopwatch', '计时器', '记录', '追踪', 'track', '统计'
    ];
    
    for (final pattern in stopwatchPatterns) {
      if (input.contains(pattern.toLowerCase())) {
        return TimerMode.stopwatch;
      }
    }
    
    // Default to countdown if time is specified, otherwise stopwatch
    return input.contains(RegExp(r'\d+')) ? TimerMode.countdown : TimerMode.stopwatch;
  }

  static String _extractTaskName(String input) {
    // Remove time information
    String cleaned = input;
    
    // Remove time duration patterns
    final timePatterns = [
      r'半\s*[个]?\s*(小时|hour|小时|h)',  // 半小时, 半个小时
      r'半\s*(分钟|min|分钟|分)',  // 半分钟
      r'\d+\s*(分钟|min|分钟|分)',
      r'[一二三四五六七八九十\d]+(?:\.\d+)?\s*[个]?\s*(小时|hour|小时|h)',
      r'\d+\s*(秒|second|秒|s)',
      r'(番茄|pomodoro|番茄钟)',
      r'(快速|quick|5分钟)',
      r'(长|long|深度|deep)',
      r'\d{1,2}[月/-]\d{1,2}[日号]?',
    ];
    
    for (final pattern in timePatterns) {
      cleaned = cleaned.replaceAll(RegExp(pattern, caseSensitive: false), '');
    }
    
    // Remove time point patterns (e.g., "下午3点", "18:30")
    final timePointPatterns = [
      r'(上午|早上|下午|晚上|傍晚|中午|morning|afternoon|evening|night)\s*[一二三四五六七八九十\d]+\s*点\s*(半)?',
      r'\d{1,2}\s*[:：点]\s*\d{0,2}\s*(分)?',
    ];
    
    for (final pattern in timePointPatterns) {
      cleaned = cleaned.replaceAll(RegExp(pattern, caseSensitive: false), '');
    }
    
    // Remove priority keywords
    final priorityPatterns = [
      '紧急', 'urgent', '重要', 'important', '马上', '立刻', '立即',
      'asap', 'critical', 'priority', '优先', '高', 'high', '低', 'low'
    ];
    
    for (final pattern in priorityPatterns) {
      cleaned = cleaned.replaceAll(RegExp(pattern, caseSensitive: false), '');
    }
    
    // Remove due date keywords
    final dueDatePatterns = [
      '今天', 'today', '今日', '明天', 'tomorrow', '明日',
      '本周', 'this week', '这周', '本月', 'this month', '这个月'
    ];
    
    for (final pattern in dueDatePatterns) {
      cleaned = cleaned.replaceAll(RegExp(pattern, caseSensitive: false), '');
    }
    
    // Clean up extra spaces and punctuation
    cleaned = cleaned
        .replaceAll(RegExp(r'[,，.。!！?？]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    return cleaned.isEmpty ? '新任务' : cleaned;
  }

  static double _calculateConfidence(String originalInput, String taskName, TimeResult timeResult) {
    double confidence = 0.5; // Base confidence
    
    // Confidence based on task name quality
    if (taskName.length > 2) confidence += 0.2;
    if (taskName.length > 5) confidence += 0.1;
    
    // Confidence based on time extraction
    if (timeResult.hasTime) confidence += 0.2;
    
    // Confidence based on input length
    if (originalInput.length > 10) confidence += 0.1;
    
    return confidence.clamp(0.0, 1.0);
  }
}

class TaskParseResult {
  final String name;
  final TimerMode mode;
  final int targetSeconds;
  final Priority priority;
  final List<Tag> tags;
  final DateTime? dueDate;
  final double confidence;

  TaskParseResult({
    required this.name,
    required this.mode,
    required this.targetSeconds,
    required this.priority,
    required this.tags,
    this.dueDate,
    required this.confidence,
  });
}

class TimeResult {
  final int seconds;
  final bool hasTime;

  TimeResult({required this.seconds, required this.hasTime});
}