import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/task.dart';
import '../state/app_state.dart';
import 'edit_task_page.dart';

class TimerPage extends StatefulWidget {
  final String taskId;
  const TimerPage({super.key, required this.taskId});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  bool _shownCongrats = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      final t = state.tasks.firstWhere((e) => e.id == widget.taskId);
      final active = state.activeTaskId == widget.taskId;
      final paused = state.paused;
      final isCountdown = t.mode == TimerMode.countdown;
      final mainSeconds = isCountdown ? t.remainingSeconds : t.elapsedSeconds;

      if (state.resting && !_shownCongrats) {
        _shownCongrats = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('恭喜完成'),
              content: const Text('休息一下，继续加油'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('好的'),
                ),
              ],
            ),
          );
        });
      }

      final progress = isCountdown && t.targetSeconds > 0
          ? (t.elapsedSeconds / t.targetSeconds).clamp(0.0, 1.0)
          : null;
      return Scaffold(
        appBar: AppBar(
          title: Text(t.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EditTaskPage(task: t)),
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
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!active) ...[
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: SvgPicture.asset(
                          'assets/illustrations/timer_focus.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CustomPaint(
                        painter: progress != null
                            ? _RingPainter(progress: progress)
                            : _RingPainterStatic(),
                        child: Center(
                          child: _GradientTimeText(text: _format(mainSeconds)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(isCountdown ? '倒计时' : '计时'),
                    const SizedBox(height: 28),
                    if (active) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.tonal(
                            onPressed: active && !paused ? state.pauseTask : state.resumeTask,
                            child: Text(active && !paused ? '暂停' : '继续'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('确认完成'),
                                  content: const Text('确定要完成这个任务吗？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('取消'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('完成'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                state.manualCompleteActive();
                              }
                            },
                            child: const Text('完成'),
                          ),
                        ],
                      ),
                    ] else ...[
                      _GlassStartButton(
                        onPressed: () => state.startTask(widget.taskId),
                      ),
                    ],
                  ],
                ),
              ),
              if (state.resting) _RestOverlay(onSkip: state.skipRest),
            ],
          ),
        ),
      );
    });
  }

  static String _format(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _GlassStartButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GlassStartButton({required this.onPressed});
  
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  c.primary.withValues(alpha: 0.3),
                  c.secondary.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: c.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [c.primary, c.secondary],
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  '开始任务',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
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

class _RestOverlay extends StatelessWidget {
  final VoidCallback onSkip;
  const _RestOverlay({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.primary.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: c.primary.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 12)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/illustrations/timer_focus.svg',
                width: 80,
                height: 80,
                colorFilter: ColorFilter.mode(c.primary, BlendMode.srcIn),
              ),
              const SizedBox(height: 16),
              Text(
                '休息时间到～',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: c.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '让大脑放松一下，准备迎接下一个任务！',
                style: TextStyle(
                  fontSize: 14,
                  color: c.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: onSkip, child: const Text('跳过休息')),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientTimeText extends StatelessWidget {
  final String text;
  const _GradientTimeText({required this.text});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final shader = LinearGradient(colors: [c.primary, c.secondary]).createShader(const Rect.fromLTWH(0, 0, 200, 60));
    return Text(text, style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700, foreground: Paint()..shader = shader));
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final track = Paint()
      ..color = const Color(0xFFE6ECF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final sweep = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF5B8CFF), Color(0xFF51E1A7)])
          .createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    final startAngle = -90 * 3.1415926 / 180;
    final sweepAngle = 2 * 3.1415926 * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, sweep);
  }
  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

class _RingPainterStatic extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final track = Paint()
      ..color = const Color(0xFFE6ECF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
  }
  @override
  bool shouldRepaint(covariant _RingPainterStatic old) => false;
}
