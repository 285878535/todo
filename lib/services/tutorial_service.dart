import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 引导步骤定义
class TutorialStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Offset? targetPosition;
  final Size? targetSize;
  final bool needsInteraction;
  final String? actionHint;

  TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.targetPosition,
    this.targetSize,
    this.needsInteraction = false,
    this.actionHint,
  });
}

/// 引导服务
class TutorialService {
  static const String _tutorialCompletedKey = 'tutorial_completed';
  static const String _currentStepKey = 'tutorial_current_step';

  /// 检查是否已完成引导
  static Future<bool> isTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialCompletedKey) ?? false;
  }

  /// 标记引导已完成
  static Future<void> setTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, true);
  }

  /// 重置引导（用于测试）
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialCompletedKey);
    await prefs.remove(_currentStepKey);
  }

  /// 获取当前步骤索引
  static Future<int> getCurrentStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentStepKey) ?? 0;
  }

  /// 保存当前步骤索引
  static Future<void> saveCurrentStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentStepKey, step);
  }

  /// 主页引导步骤
  static List<TutorialStep> getHomePageSteps() {
    return [
      TutorialStep(
        id: 'welcome',
        title: '欢迎使用即刻清单！',
        description: '让我们快速了解一下如何使用这个应用。点击"下一步"开始新手引导。',
        icon: Icons.waving_hand,
      ),
      TutorialStep(
        id: 'add_task',
        title: '创建新任务',
        description: '点击右下角的 ➕ 按钮，可以快速创建新任务。',
        icon: Icons.add_circle_outline,
        actionHint: '试试点击这个按钮',
      ),
      TutorialStep(
        id: 'smart_task',
        title: '智能任务创建',
        description: '点击右下角的 ✨ 按钮，可以使用自然语言创建任务！\n\n例如："明天下午3点开会一小时"\n系统会自动识别时间、时长和优先级。',
        icon: Icons.auto_awesome,
        actionHint: '试试智能创建',
      ),
      TutorialStep(
        id: 'swipe_actions',
        title: '快速操作',
        description: '在任务上向左滑动，可以快速编辑或删除任务。',
        icon: Icons.swipe_left,
        needsInteraction: true,
        actionHint: '向左滑动任务试试',
      ),
      TutorialStep(
        id: 'stats',
        title: '查看统计',
        description: '点击右上角的 📊 图标，可以查看你的完成情况、时间统计和成就。',
        icon: Icons.bar_chart,
        actionHint: '查看统计数据',
      ),
      TutorialStep(
        id: 'settings',
        title: '个性化设置',
        description: '点击右上角的 ⚙️ 图标，可以切换主题、调整休息时间等。',
        icon: Icons.settings,
        actionHint: '打开设置',
      ),
    ];
  }

  /// 任务详情页引导步骤
  static List<TutorialStep> getTaskDetailSteps() {
    return [
      TutorialStep(
        id: 'task_start',
        title: '开始任务',
        description: '点击中间的"开始任务"按钮，开始计时专注工作。\n\n• 倒计时模式：设定目标时间，倒数计时\n• 正计时模式：记录你花费的时间',
        icon: Icons.play_circle_outline,
        actionHint: '开始你的第一个任务',
      ),
      TutorialStep(
        id: 'task_pause',
        title: '暂停与继续',
        description: '任务进行中，可以随时暂停休息，继续时会从暂停处开始。',
        icon: Icons.pause_circle_outline,
      ),
      TutorialStep(
        id: 'task_complete',
        title: '完成任务',
        description: '任务完成后，点击"完成"按钮，系统会记录你的成就，并进入休息倒计时。',
        icon: Icons.check_circle_outline,
      ),
      TutorialStep(
        id: 'task_edit',
        title: '编辑任务',
        description: '点击右上角的编辑图标，可以修改任务的名称、时长、优先级等信息。',
        icon: Icons.edit_outlined,
      ),
    ];
  }

  /// 设置页面引导步骤
  static List<TutorialStep> getSettingsSteps() {
    return [
      TutorialStep(
        id: 'settings_theme',
        title: '切换主题',
        description: '选择你喜欢的主题：\n\n• 自动：跟随系统\n• 陶瓷白：清爽简洁\n• 午夜蓝：护眼深色\n• 可爱粉：温馨可爱\n• 清新绿：自然清新',
        icon: Icons.palette_outlined,
        actionHint: '试试切换主题',
      ),
      TutorialStep(
        id: 'settings_rest',
        title: '休息时间设置',
        description: '可以调整任务完成后的休息时长，劳逸结合更健康！',
        icon: Icons.timer_outlined,
      ),
      TutorialStep(
        id: 'settings_about',
        title: '关于与更新',
        description: '在这里可以查看应用版本、检查更新，以及了解开发者信息。',
        icon: Icons.info_outlined,
      ),
    ];
  }
}

/// 引导覆盖层 Widget
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final int initialStep;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.onSkip,
    this.initialStep = 0,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late int _currentStep;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
      TutorialService.saveCurrentStep(_currentStep);
    } else {
      _complete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
      TutorialService.saveCurrentStep(_currentStep);
    }
  }

  void _complete() {
    TutorialService.setTutorialCompleted();
    widget.onComplete();
  }

  void _skip() {
    TutorialService.setTutorialCompleted();
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];

    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Stack(
        children: [
          // 点击背景跳过
          GestureDetector(
            onTap: () {}, // 阻止点击穿透
            child: Container(color: Colors.transparent),
          ),

          // 提示卡片
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 图标
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          step.icon,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 标题
                      Text(
                        step.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // 描述
                      Text(
                        step.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      // 操作提示
                      if (step.actionHint != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                step.actionHint!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 进度指示器
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.steps.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: index == _currentStep ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: index == _currentStep
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 按钮
                      Row(
                        children: [
                          // 跳过按钮
                          TextButton(
                            onPressed: _skip,
                            child: const Text('跳过'),
                          ),
                          const SizedBox(width: 8),

                          // 上一步按钮
                          if (_currentStep > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _previousStep,
                                child: const Text('上一步'),
                              ),
                            ),
                          if (_currentStep > 0) const SizedBox(width: 8),

                          // 下一步/完成按钮
                          Expanded(
                            flex: _currentStep > 0 ? 1 : 2,
                            child: FilledButton(
                              onPressed: _nextStep,
                              child: Text(
                                _currentStep < widget.steps.length - 1
                                    ? '下一步'
                                    : '开始使用',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

