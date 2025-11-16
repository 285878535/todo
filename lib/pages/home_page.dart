import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../state/app_state.dart';
import '../models/task.dart';
import '../utils/recurring_task_manager.dart';
import '../utils/page_transitions.dart';
import '../services/tutorial_service.dart';
import 'edit_task_page.dart';
import 'settings_page.dart';
import 'stats_page.dart';
import 'timer_page.dart';
import 'nlp_task_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _tutorialShown = false;

  @override
  void initState() {
    super.initState();
    _checkAndShowTutorial();
  }

  Future<void> _checkAndShowTutorial() async {
    // 等待第一帧渲染完成
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    
    // 等待 AppState 初始化完成（不再需要等待创建示例任务）
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    
    final completed = await TutorialService.isTutorialCompleted();
    
    if (!completed && !_tutorialShown) {
      _tutorialShown = true;
      // 使用 addPostFrameCallback 确保在帧渲染后显示
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showTutorial();
        }
      });
    }
  }

  void _showTutorial() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialOverlay(
        steps: TutorialService.getHomePageSteps(),
        onComplete: () {
          Navigator.of(context).pop();
        },
        onSkip: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('即刻清单'),
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                Navigator.of(context).push(
                  FadePageRoute(page: const StatsPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  FadePageRoute(page: const SettingsPage()),
                );
              },
            ),
          ],
        ),
        body: state.tasks.isEmpty
            ? const _EmptyView()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.tasks.length,
                itemBuilder: (context, index) {
                    final t = state.tasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Slidable(
                        key: ValueKey(t.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                Navigator.of(context).push(
                                  FadePageRoute(page: EditTaskPage(task: t)),
                                );
                              },
                              backgroundColor: const Color(0xFF0288D1),
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              label: '编辑',
                              borderRadius: BorderRadius.circular(16),
                            ),
                            SlidableAction(
                              onPressed: (context) {
                                state.deleteTask(t.id);
                              },
                              backgroundColor: const Color(0xFFD32F2F),
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: '删除',
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ],
                        ),
                        child: _TaskCard(
                          task: t,
                          onTap: () {
                            // 点击列表项进入计时页面，但不自动开始
                            Navigator.of(context).push(
                              ScaleFadePageRoute(page: TimerPage(taskId: t.id)),
                            );
                          },
                        ),
                      ),
                    );
                },
              ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const NlpTaskDialog(),
                );
              },
              heroTag: 'nlp',
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.psychology),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  FadePageRoute(page: const EditTaskPage()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('新建清单'),
            ),
          ],
        ),
      );
    });
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final isDark = c.brightness == Brightness.dark;
    
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.all(40),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        c.surface.withValues(alpha: 0.5),
                        c.surface.withValues(alpha: 0.3),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.6),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? c.onSurface.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: c.primary.withValues(alpha: 0.1), 
                  blurRadius: 30, 
                  offset: const Offset(0, 15),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: SvgPicture.asset(
                'assets/illustrations/empty_tasks.svg',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '还没有任务哦～',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: c.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '创建你的第一个任务，开始培养好习惯吧！',
              style: TextStyle(
                fontSize: 14,
                color: c.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  FadePageRoute(page: const EditTaskPage()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('创建任务'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  const _TaskCard({
    required this.task,
    required this.onTap,
  });

  String _format(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final isDark = c.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: task.isOverdue 
                ? (isDark 
                    ? const Color(0xFF4A1F1F)
                    : const Color(0xFFFFEBEE))
                : (isDark
                    ? c.surface.withValues(alpha: 0.9)
                    : Colors.white),
              border: Border.all(
                color: task.isOverdue
                  ? Colors.red.withValues(alpha: isDark ? 0.4 : 0.2)
                  : (isDark 
                      ? c.onSurface.withValues(alpha: 0.2)
                      : c.outline.withValues(alpha: 0.12)),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: task.isOverdue 
                    ? Colors.red.withValues(alpha: 0.15) 
                    : (isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.08)), 
                  blurRadius: isDark ? 16 : 12, 
                  offset: Offset(0, isDark ? 6 : 4),
                  spreadRadius: isDark ? -2 : -1,
                ),
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: task.isOverdue 
                      ? [Colors.red, Colors.redAccent]
                      : [c.primary, c.secondary]
                  ),
                ),
                child: Icon(
                  task.mode == TimerMode.countdown ? Icons.timer : Icons.schedule, 
                  color: Colors.white
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.name, 
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.w600,
                              decoration: task.completed ? TextDecoration.lineThrough : null,
                              decorationThickness: 2,
                              color: task.completed 
                                  ? c.onSurface.withValues(alpha: 0.5)
                                  : c.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (task.isOverdue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '已逾期',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ] else if (task.dueDate != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${task.daysUntilDue}天后',
                              style: TextStyle(
                                color: c.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ] else if (task.isRecurring && task.recurringPattern != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.tertiary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  RecurringTaskManager.getPatternIcon(task.recurringPattern!),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  RecurringTaskManager.getPatternDescription(task.recurringPattern!),
                                  style: TextStyle(
                                    color: c.tertiary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 时间信息行
                    Row(
                      children: [
                        if (task.mode == TimerMode.countdown) ...[
                          _InfoChip(
                            icon: Icons.flag_outlined,
                            label: '目标',
                            value: _format(task.targetSeconds),
                            color: c.primary,
                          ),
                          const SizedBox(width: 6),
                          _InfoChip(
                            icon: Icons.timelapse,
                            label: '剩余',
                            value: _format(task.remainingSeconds),
                            color: c.secondary,
                          ),
                          const SizedBox(width: 6),
                        ] else ...[
                          _InfoChip(
                            icon: Icons.timer_outlined,
                            label: '已用时',
                            value: _format(task.elapsedSeconds),
                            color: c.primary,
                          ),
                          const SizedBox(width: 6),
                        ],
                        _InfoChip(
                          icon: Icons.local_fire_department,
                          label: '连续',
                          value: '${task.streak}天',
                          color: const Color(0xFFFF6B35),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 标签和优先级行
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        // 优先级徽章
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: task.getPriorityColor().withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: task.getPriorityColor().withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(task.getPriorityIcon(), size: 13, color: task.getPriorityColor()),
                              const SizedBox(width: 4),
                              Text(
                                task.getPriorityLabel(),
                                style: TextStyle(
                                  color: task.getPriorityColor(),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 标签徽章
                        ...task.tags.take(2).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.secondary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: c.secondary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(task.getTagIcon(tag), size: 13, color: c.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  task.getTagLabel(tag),
                                  style: TextStyle(
                                    color: c.secondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (task.tags.length > 2)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.outline.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '+${task.tags.length - 2}',
                              style: TextStyle(
                                color: c.outline,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    ),
    );
  }
}

class _InfoChip extends StatelessWidget{
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

