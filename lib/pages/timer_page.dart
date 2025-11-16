import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/task.dart';
import '../state/app_state.dart';
import '../utils/page_transitions.dart';
import 'edit_task_page.dart';
import '../services/audio_service.dart';

class TimerPage extends StatefulWidget {
  final String taskId;
  const TimerPage({super.key, required this.taskId});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  bool _shownCongrats = false;
  String? _lastActiveTaskId;
  bool _isLandscape = false;
  bool? _wasCompletedOnOpen; // 记录打开页面时任务是否已完成

  @override
  void dispose() {
    // 恢复屏幕方向
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // 离开任务详情时暂停背景音乐
    AudioService.instance.pauseBgm();
    super.dispose();
  }

  void _pauseTimerAndBgm(AppState state) {
    state.pauseTask();
    AudioService.instance.pauseBgm();
  }

  void _resumeTimerAndBgm(AppState state) {
    state.resumeTask();
    // 仅当选择了某个BGM时才播放
    if (AudioService.instance.currentBgm != BgmType.none) {
      AudioService.instance.playBgm();
    }
  }

  Future<bool> _onWillPop(BuildContext context, bool active, bool paused, AppState state) async {
    if (active && !paused) {
      final shouldPause = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('任务进行中'),
          content: const Text('任务正在进行，是否暂停任务并返回？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('继续计时'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('暂停并返回'),
            ),
          ],
        ),
      );
      if (shouldPause == true) {
        state.pauseTask();
        return true;
      }
      return false;
    }
    return true;
  }

  void _handleOrientationChange(Orientation orientation, bool active, bool resting) {
    final isLandscapeNow = orientation == Orientation.landscape;
    
    if (isLandscapeNow != _isLandscape) {
      setState(() {
        _isLandscape = isLandscapeNow;
      });
      
      if (isLandscapeNow && active && !resting) {
        // 横屏时全屏显示
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        // 竖屏时恢复正常
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      final t = state.tasks.firstWhere((e) => e.id == widget.taskId);
      final active = state.activeTaskId == widget.taskId;
      final paused = state.paused;
      final isCountdown = t.mode == TimerMode.countdown;
      final mainSeconds = isCountdown ? t.remainingSeconds : t.elapsedSeconds;
      final isCompleted = t.completed;

      // 如果切换了任务，重置弹窗状态并记录任务初始完成状态
      if (_lastActiveTaskId != widget.taskId) {
        _shownCongrats = false;
        _lastActiveTaskId = widget.taskId;
        _wasCompletedOnOpen = isCompleted; // 记录打开时是否已完成
      }

      // 只有满足以下所有条件才显示完成弹窗：
      // 1. 正在休息状态
      // 2. 还没显示过弹窗
      // 3. 任务现在是完成状态
      // 4. 任务打开时未完成（说明是刚刚完成的）
      // 5. 没有其他活动任务，或当前任务就是活动任务
      final shouldShowCompletionDialog = state.resting && 
                                         !_shownCongrats && 
                                         isCompleted && 
                                         _wasCompletedOnOpen == false &&
                                         (state.activeTaskId == null || state.activeTaskId == widget.taskId);

      if (shouldShowCompletionDialog) {
        _shownCongrats = true;
        // 休息时恢复竖屏
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
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
          }
        });
      }

      final progress = isCountdown && t.targetSeconds > 0
          ? (t.elapsedSeconds / t.targetSeconds).clamp(0.0, 1.0)
          : null;
      final c = Theme.of(context).colorScheme;
      
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          final shouldPop = await _onWillPop(context, active, paused, state);
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: OrientationBuilder(
          builder: (context, orientation) {
            // 处理横竖屏切换
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleOrientationChange(orientation, active, state.resting);
            });

            // 横屏全屏大时钟模式
            if (orientation == Orientation.landscape && active && !state.resting) {
              return _LandscapeTimerView(
                task: t,
                mainSeconds: mainSeconds,
                progress: progress,
                paused: paused,
                onPauseResume: paused ? () => _resumeTimerAndBgm(state) : () => _pauseTimerAndBgm(state),
                onComplete: () async {
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
                    // 恢复竖屏
                    await SystemChrome.setPreferredOrientations([
                      DeviceOrientation.portraitUp,
                    ]);
                    await AudioService.instance.playSfxComplete();
                    await AudioService.instance.pauseBgm();
                    state.manualCompleteActive();
                  }
                },
              );
            }

            // 竖屏正常模式
            return Scaffold(
        appBar: AppBar(
          title: Text(t.name),
          actions: [
            // 只在任务未开始、未完成、且不在休息状态时显示编辑按钮
            if (!active && !isCompleted && !state.resting)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    FadePageRoute(page: EditTaskPage(task: t)),
                  );
                },
              ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: c.brightness == Brightness.dark
                ? [
                    c.surface,
                    c.surface.withValues(alpha: 0.9),
                    c.surface.withValues(alpha: 0.95),
                  ]
                : [
                    const Color(0xFFE0F2FE),
                    const Color(0xFFFCE7F3),
                    const Color(0xFFDDD6FE),
                  ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // 自定义毛玻璃“背景音”按钮（仅任务进行中显示）
              if (active && !state.resting)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _GlassBgmButton(
                    onPressed: () => _showBgmSheet(context),
                    isPlaying: active && !paused && !state.resting && AudioService.instance.currentBgm != BgmType.none,
                    label: AudioService.instance.currentBgm == BgmType.none
                        ? '背景音'
                        : _bgmLabel(AudioService.instance.currentBgm),
                  ),
                ),
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
                    if (isCompleted) ...[
                      // 已完成的任务只显示提示
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              '任务已完成',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (active) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.tonal(
                            onPressed: active && !paused ? () => _pauseTimerAndBgm(state) : () => _resumeTimerAndBgm(state),
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
                        onPressed: () {
                          // 先启动计时，确保UI立即进入进行中状态
                          state.startTask(widget.taskId);
                          // 音效与BGM不阻塞UI
                          AudioService.instance.playSfxStart();
                          AudioService.instance.playBgm();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              // 只有当前任务刚完成时才显示休息覆盖层
              if (state.resting && isCompleted && _wasCompletedOnOpen == false) 
                _RestOverlay(
                  onSkip: () {
                    state.skipRest();
                    Navigator.of(context).pop(); // 返回到任务列表
                  },
                ),
            ],
          ),
        ),
      );
          },
        ),
      );
    });
  }

  void _showBgmSheet(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    c.surface.withValues(alpha: 0.98),
                    c.surface.withValues(alpha: 0.94),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: c.outline.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _BgmPickerContent(),
            ),
          ),
        );
      },
    );
  }

  String _bgmLabel(BgmType type) {
    switch (type) {
      case BgmType.none:
        return '背景音';
      case BgmType.lightMusic:
        return '轻音乐';
      case BgmType.piano:
        return '钢琴';
      case BgmType.ocean:
        return '海浪-海鸥';
      case BgmType.rain:
      case BgmType.heavy_rain:
        return '大雨-风铃';
      case BgmType.bambooRain:
        return '竹林雨';
    }
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
    final isDark = c.brightness == Brightness.dark;
    
    return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                c.primary.withValues(alpha: 0.15),
                isDark 
                  ? Colors.black.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                        ? [
                            c.surface.withValues(alpha: 0.95),
                            c.surface.withValues(alpha: 0.85),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.9),
                            Colors.white.withValues(alpha: 0.7),
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
                        color: c.primary.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                        spreadRadius: -5,
                      ),
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

class _GlassBgmButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isPlaying;
  final String label;
  const _GlassBgmButton({required this.onPressed, required this.isPlaying, required this.label});
  @override
  State<_GlassBgmButton> createState() => _GlassBgmButtonState();
}

class _GlassBgmButtonState extends State<_GlassBgmButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void didUpdateWidget(covariant _GlassBgmButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isPlaying) {
      _controller.stop();
    } else {
      if (!_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: c.surface.withValues(alpha: 0.5),
          child: InkWell(
            onTap: widget.onPressed,
            splashColor: c.primary.withValues(alpha: 0.2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final angle = widget.isPlaying ? _controller.value * 6.2831853 : 0.0;
                      return Transform.rotate(
                        angle: angle,
                        child: const Icon(Icons.music_note, color: Colors.white),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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

class _BgmPickerContent extends StatefulWidget {
  @override
  State<_BgmPickerContent> createState() => _BgmPickerContentState();
}

class _RotatingMusicIcon extends StatefulWidget {
  @override
  State<_RotatingMusicIcon> createState() => _RotatingMusicIconState();
}

class _RotatingMusicIconState extends State<_RotatingMusicIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.watch<AppState>();
    final isPlaying = appState.activeTaskId != null &&
        !appState.paused &&
        !appState.resting &&
        AudioService.instance.currentBgm != BgmType.none;
    if (isPlaying) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Transform.rotate(
          angle: _c.value * 6.2831853,
          child: Icon(Icons.music_note, color: Theme.of(context).colorScheme.primary),
        );
      },
    );
  }
}

class _BgmPickerContentState extends State<_BgmPickerContent> {
  late BgmType _bgm = AudioService.instance.currentBgm;
  late double _bgmVolume = AudioService.instance.bgmVolume;
  late double _sfxVolume = AudioService.instance.sfxVolume;

  String _label(BgmType type) {
    switch (type) {
      case BgmType.none:
        return '背景音';
      case BgmType.lightMusic:
        return '轻音乐';
      case BgmType.piano:
        return '钢琴';
      case BgmType.ocean:
        return '海浪-海鸥';
      case BgmType.rain:
      case BgmType.heavy_rain:
        return '大雨-风铃';
      case BgmType.bambooRain:
        return '竹林雨';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final appState = context.watch<AppState>();
    final isActive = appState.activeTaskId != null && !appState.resting;
    final isPaused = appState.paused;
    final isPlayingUi = isActive && !isPaused && _bgm != BgmType.none;
    final chips = <Map<String, dynamic>>[
      {'t': '关闭', 'v': BgmType.none},
      {'t': '轻音乐', 'v': BgmType.lightMusic},
      {'t': '钢琴', 'v': BgmType.piano},
      {'t': '海浪-海鸥', 'v': BgmType.ocean},
      {'t': '大雨-风铃', 'v': BgmType.heavy_rain},
      {'t': '竹林雨', 'v': BgmType.bambooRain},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RotatingMusicIcon(),
              const SizedBox(width: 8),
              Text(
                AudioService.instance.currentBgm == BgmType.none
                    ? '背景音'
                    : _label(AudioService.instance.currentBgm),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () async {
                  if (_bgm == BgmType.none || !isActive) return;
                  if (!isPaused) {
                    appState.pauseTask();
                    await AudioService.instance.pauseBgm();
                  } else {
                    appState.resumeTask();
                    await AudioService.instance.playBgm();
                  }
                },
                icon: Icon(isPlayingUi ? Icons.pause : Icons.play_arrow),
                label: Text(isPlayingUi ? '暂停' : '播放'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips.map((e) {
                final selected = _bgm == e['v'] as BgmType;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selected,
                    label: Text(e['t'] as String),
                    selectedColor: c.primary.withValues(alpha: 0.15),
                    onSelected: (s) async {
                      if (!s) return;
                      final val = e['v'] as BgmType;
                      setState(() => _bgm = val);
                      await AudioService.instance.setBgm(val);
                      if (val == BgmType.none) {
                        await AudioService.instance.stopBgm();
                      } else {
                        // 仅当当前在计时状态时自动播放
                        final appState = context.read<AppState>();
                        if (appState.activeTaskId != null && !appState.paused && !appState.resting) {
                          await AudioService.instance.playBgm();
                        }
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.volume_down_alt),
              const SizedBox(width: 12),
              const Text('背景音量'),
              Expanded(
                child: Slider(
                  value: _bgmVolume,
                  onChanged: (v) async {
                    setState(() => _bgmVolume = v);
                    await AudioService.instance.setBgmVolume(v);
                  },
                  min: 0.0,
                  max: 1.0,
                ),
              ),
              Text('${(_bgmVolume * 100).round()}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined),
              const SizedBox(width: 12),
              const Text('提示音量'),
              Expanded(
                child: Slider(
                  value: _sfxVolume,
                  onChanged: (v) async {
                    setState(() => _sfxVolume = v);
                    await AudioService.instance.setSfxVolume(v);
                  },
                  min: 0.0,
                  max: 1.0,
                ),
              ),
              Text('${(_sfxVolume * 100).round()}'),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
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

/// 横屏全屏大时钟视图
class _LandscapeTimerView extends StatelessWidget {
  final Task task;
  final int mainSeconds;
  final double? progress;
  final bool paused;
  final VoidCallback onPauseResume;
  final VoidCallback onComplete;

  const _LandscapeTimerView({
    required this.task,
    required this.mainSeconds,
    required this.progress,
    required this.paused,
    required this.onPauseResume,
    required this.onComplete,
  });

  String _format(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final isDark = c.brightness == Brightness.dark;
    final isCountdown = task.mode == TimerMode.countdown;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : c.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
              ? [
                  Colors.black,
                  const Color(0xFF1a1a1a),
                ]
              : [
                  const Color(0xFFE0F2FE),
                  const Color(0xFFFCE7F3),
                ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 大时钟居中显示
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 任务名称
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        task.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : c.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // 超大时钟
                    SizedBox(
                      width: 320,
                      height: 320,
                      child: CustomPaint(
                        painter: progress != null
                            ? _LandscapeRingPainter(progress: progress!, isDark: isDark)
                            : _LandscapeRingPainterStatic(isDark: isDark),
                        child: Center(
                          child: ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: isDark
                                  ? [const Color(0xFF64B5F6), const Color(0xFF81C784)]
                                  : [c.primary, c.secondary],
                              ).createShader(bounds);
                            },
                            child: Text(
                              _format(mainSeconds),
                              style: TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 倒计时/计时标签
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark 
                          ? Colors.white.withValues(alpha: 0.1)
                          : c.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isCountdown ? '倒计时' : '计时',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : c.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 底部控制按钮
              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 暂停/继续按钮
                    _LandscapeControlButton(
                      icon: paused ? Icons.play_arrow : Icons.pause,
                      label: paused ? '继续' : '暂停',
                      onPressed: onPauseResume,
                      isDark: isDark,
                      isPrimary: false,
                    ),
                    const SizedBox(width: 32),
                    // 完成按钮
                    _LandscapeControlButton(
                      icon: Icons.check_circle,
                      label: '完成',
                      onPressed: onComplete,
                      isDark: isDark,
                      isPrimary: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 横屏模式控制按钮
class _LandscapeControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDark;
  final bool isPrimary;

  const _LandscapeControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isDark,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPrimary
              ? isDark
                ? [const Color(0xFF1E88E5), const Color(0xFF1565C0)]
                : [c.primary, c.secondary]
              : isDark
                ? [const Color(0xFF424242), const Color(0xFF212121)]
                : [c.surface.withValues(alpha: 0.8), c.surface.withValues(alpha: 0.6)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                ? (isDark ? Colors.blue : c.primary).withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary || isDark ? Colors.white : c.onSurface,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isPrimary || isDark ? Colors.white : c.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 横屏模式进度环绘制器
class _LandscapeRingPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  
  _LandscapeRingPainter({required this.progress, required this.isDark});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final track = Paint()
      ..color = isDark 
        ? const Color(0xFF424242)
        : const Color(0xFFE6ECF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    final sweep = Paint()
      ..shader = LinearGradient(
        colors: isDark
          ? [const Color(0xFF64B5F6), const Color(0xFF81C784)]
          : [const Color(0xFF5B8CFF), const Color(0xFF51E1A7)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    final startAngle = -90 * 3.1415926 / 180;
    final sweepAngle = 2 * 3.1415926 * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, sweep);
  }
  
  @override
  bool shouldRepaint(covariant _LandscapeRingPainter old) => 
    old.progress != progress || old.isDark != isDark;
}

/// 横屏模式静态环绘制器
class _LandscapeRingPainterStatic extends CustomPainter {
  final bool isDark;
  
  _LandscapeRingPainterStatic({required this.isDark});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final track = Paint()
      ..color = isDark 
        ? const Color(0xFF424242)
        : const Color(0xFFE6ECF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
  }
  
  @override
  bool shouldRepaint(covariant _LandscapeRingPainterStatic old) => old.isDark != isDark;
}
