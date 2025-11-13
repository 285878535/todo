import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../state/app_state.dart';
import '../models/task.dart';
import '../utils/recurring_task_manager.dart';
import 'edit_task_page.dart';
import 'settings_page.dart';
import 'stats_page.dart';
import 'timer_page.dart';
import 'nlp_task_dialog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('习惯待办'),
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StatsPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEAF1FF), Color(0xFFFDF7F2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: state.tasks.isEmpty
              ? const _EmptyView()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.tasks.length,
                  itemBuilder: (context, index) {
                    final t = state.tasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TaskCard(
                        task: t,
                        onTap: () {
                          // 点击列表项进入计时页面，但不自动开始
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => TimerPage(taskId: t.id)),
                          );
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('确认删除'),
                              content: Text('确定要删除任务"${t.name}"吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('取消'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            state.deleteTask(t.id);
                          }
                        },
                        onPlay: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('开始任务'),
                              content: Text('开始任务"${t.name}"？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('取消'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('开始'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            state.startTask(t.id);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => TimerPage(taskId: t.id)),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
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
                  MaterialPageRoute(builder: (_) => const EditTaskPage()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('新建任务'),
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
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: c.primary.withValues(alpha: 0.08), 
              blurRadius: 24, 
              offset: const Offset(0, 12)
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
                  MaterialPageRoute(
                    builder: (_) => const EditTaskPage(),
                  ),
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
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onPlay;
  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onDelete,
    required this.onPlay,
  });

  String _format(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: task.isOverdue 
              ? [const Color(0xFFFFF5F5), const Color(0xFFFFFBFB)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF9FBFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: task.isOverdue 
                ? Colors.red.withValues(alpha: 0.1) 
                : c.primary.withValues(alpha: 0.06), 
              blurRadius: 16, 
              offset: const Offset(0, 8)
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
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                        }).toList(),
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconPill(
                    icon: Icons.play_arrow, 
                    onTap: (e) {
                      e.stopPropagation();
                      onPlay();
                    }, 
                    primary: true
                  ),
                  const SizedBox(height: 8),
                  _IconPill(
                    icon: Icons.delete_outline, 
                    onTap: (e) {
                      e.stopPropagation();
                      onDelete();
                    },
                    danger: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
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

class _IconPill extends StatelessWidget {
  final IconData icon;
  final Function(dynamic) onTap;
  final bool primary;
  final bool danger;
  const _IconPill({
    required this.icon, 
    required this.onTap, 
    this.primary = false,
    this.danger = false,
  });
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final Color bgColor = primary 
        ? c.primary 
        : danger 
            ? Colors.red.shade50 
            : Colors.white;
    final Color iconColor = primary 
        ? Colors.white 
        : danger 
            ? Colors.red 
            : c.primary;
    
    return GestureDetector(
      onTap: () => onTap(null),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: primary 
                  ? c.primary.withValues(alpha: 0.15) 
                  : danger
                      ? Colors.red.withValues(alpha: 0.1)
                      : c.primary.withValues(alpha: 0.08), 
              blurRadius: 8, 
              offset: const Offset(0, 4)
            )
          ],
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}
