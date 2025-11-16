import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../state/app_state.dart';
import '../widgets/gradient_background.dart';
import '../theme.dart';
import '../services/update_service.dart';
import '../services/tutorial_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _version = '1.0.0';
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version; // 只显示版本号，不显示构建号
    });
  }

  Future<void> _checkUpdate() async {
    if (_isCheckingUpdate) return;

    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      // 使用自动清单地址（主+镜像）轮询
      final updateInfo = await UpdateService.checkUpdateAuto();

      if (!mounted) return;

      if (updateInfo.hasUpdate) {
        // 有新版本
        _showUpdateDialog(updateInfo);
      } else {
        // 已是最新版本
        _showMessage('当前已是最新版本');
      }
    } on UpdateCheckException catch (e) {
      if (mounted) {
        _showMessage(_mapUpdateError(e));
      }
    } catch (e) {
      if (mounted) {
        _showMessage('检查更新失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _mapUpdateError(UpdateCheckException exception) {
    switch (exception.type) {
      case UpdateErrorType.network:
        return exception.message;
      case UpdateErrorType.server:
        return '服务器开小差了（${exception.serverCode ?? exception.statusCode ?? '未知错误码'}），请稍后再试';
      case UpdateErrorType.invalidResponse:
        return '更新数据异常，请联系管理员';
      case UpdateErrorType.unknown:
        return '检查更新失败：${exception.message}';
    }
  }

  void _showTutorial() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialOverlay(
        steps: [
          ...TutorialService.getHomePageSteps(),
          ...TutorialService.getTaskDetailSteps(),
          ...TutorialService.getSettingsSteps(),
        ],
        onComplete: () {
          Navigator.of(context).pop();
        },
        onSkip: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
        title: const Text('清除所有数据'),
        content: const Text(
          '此操作将删除所有任务、记录和设置数据，且无法恢复。\n\n确定要继续吗？',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearAllData();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      final appState = context.read<AppState>();
      
      // 清除所有任务
      final tasks = List<String>.from(appState.tasks.map((t) => t.id));
      for (final id in tasks) {
        appState.deleteTask(id);
      }
      
      // 重置引导状态
      await TutorialService.resetTutorial();
      
      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('所有数据已清除'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清除失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update, color: Colors.blue),
            const SizedBox(width: 12),
            const Text('发现新版本'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 版本信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'v${info.latestVersion}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          if (info.fileSize != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '大小: ${info.fileSize}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (info.releaseDate != null)
                      Text(
                        info.releaseDate!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 更新说明
              const Text(
                '更新内容',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                info.releaseNotes,
                style: const TextStyle(fontSize: 14),
              ),
              if (info.forceUpdate) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '此版本为强制更新',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!info.forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('稍后更新'),
            ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final success = await UpdateService.openUpdateUrl(info.updateUrl);
              if (!success && mounted) {
                _showMessage('无法打开下载链接');
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('立即更新'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final needsGradient = appState.currentTheme == AppTheme.liquidGlass;
    
    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '主题设置',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ThemeOption(
                    title: '自动',
                    subtitle: '跟随系统外观',
                    icon: Icons.brightness_auto,
                    theme: AppTheme.auto,
                    currentTheme: appState.currentTheme,
                    onTap: () => appState.setTheme(AppTheme.auto),
                  ),
                  const SizedBox(height: 8),
                  _ThemeOption(
                    title: '陶瓷白',
                    subtitle: '清新简洁的浅色界面',
                    icon: Icons.light_mode,
                    theme: AppTheme.light,
                    currentTheme: appState.currentTheme,
                    onTap: () => appState.setTheme(AppTheme.light),
                  ),
                  const SizedBox(height: 8),
                  _ThemeOption(
                    title: '午夜蓝',
                    subtitle: '护眼的深色界面',
                    icon: Icons.dark_mode,
                    theme: AppTheme.dark,
                    currentTheme: appState.currentTheme,
                    onTap: () => appState.setTheme(AppTheme.dark),
                  ),
                  const SizedBox(height: 8),
                  _ThemeOption(
                    title: '可爱粉',
                    subtitle: '温馨可爱的粉色界面',
                    icon: Icons.favorite,
                    theme: AppTheme.cute,
                    currentTheme: appState.currentTheme,
                    onTap: () => appState.setTheme(AppTheme.cute),
                  ),
                  const SizedBox(height: 8),
                  _ThemeOption(
                    title: '清新绿',
                    subtitle: '清新自然的绿色界面',
                    icon: Icons.eco,
                    theme: AppTheme.fresh,
                    currentTheme: appState.currentTheme,
                    onTap: () => appState.setTheme(AppTheme.fresh),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '关于',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('应用版本'),
                    subtitle: Text(_version),
                    dense: true,
                  ),
                  ListTile(
                    leading: _isCheckingUpdate 
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.system_update_outlined),
                    title: const Text('检查更新'),
                    subtitle: Text(_isCheckingUpdate ? '检查中...' : '点击检查新版本'),
                    dense: true,
                    onTap: _isCheckingUpdate ? null : _checkUpdate,
                    enabled: !_isCheckingUpdate,
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('新手引导'),
                    subtitle: const Text('重新查看应用功能引导'),
                    dense: true,
                    onTap: () {
                      _showTutorial();
                    },
                  ),
                  
                 
                   ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('开发者'),
                    subtitle: const Text('Justin Xing'),
                    dense: true,
                  ),
                  ListTile(
                    leading: const Icon(Icons.copyright_outlined),
                    title: const Text('版权信息'),
                    subtitle: const Text('© 2025 即刻清单. All rights reserved.'),
                    dense: true,
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('功能特色'),
                    subtitle: const Text('番茄钟、习惯追踪、数据统计'),
                    dense: true,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                    title: const Text('清除所有数据', style: TextStyle(color: Colors.red)),
                    subtitle: const Text('删除所有任务和记录（不可恢复）'),
                    dense: true,
                    onTap: () {
                      _showClearDataDialog();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    
    return needsGradient 
        ? GradientBackground(child: scaffold)
        : scaffold;
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final AppTheme theme;
  final AppTheme currentTheme;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.theme,
    required this.currentTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = theme == currentTheme;
    final themeData = getThemeData(theme);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeData.colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: themeData.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}