import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'pages/home_page.dart';
import 'widgets/gradient_background.dart';
import 'widgets/custom_background.dart';
import 'widgets/decorated_background.dart';
import 'theme.dart';
import 'services/update_service.dart';
import 'services/audio_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _hasShownForceUpdate = false;

  @override
  void initState() {
    super.initState();
    // 每次启动时检查更新（包括强制更新）
    _checkUpdateOnStartup();
    // 初始化音频
    AudioService.instance.init().then((_) {
      // 默认选择轻音乐，音量适合学习（可在设置中调整/关闭）
      AudioService.instance.setBgm(BgmType.lightMusic);
      AudioService.instance.setBgmVolume(0.25);
      AudioService.instance.setSfxVolume(0.6);
    });
  }

  Future<void> _checkUpdateOnStartup() async {
    // 等待一段时间，确保应用已经完全启动
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      // 使用远程静态清单（占位 URL，替换为你的 GitHub Raw 或自建地址）
      const manifestUrl = 'https://example.com/version.json';
      final updateInfo = await UpdateService.checkUpdateFromManifest(manifestUrl);

      if (updateInfo.hasUpdate && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (updateInfo.forceUpdate) {
              // 强制更新：显示不可关闭的对话框
              _showForceUpdateDialog(updateInfo);
            } else {
              // 普通更新：显示提示
              _showUpdateSnackBar(updateInfo);
            }
          }
        });
      }
    } on UpdateCheckException catch (e) {
      debugPrint('启动检查更新失败：${e.message}');
    } catch (e) {
      debugPrint('启动检查更新出现未知错误：$e');
    }
  }

  void _showUpdateSnackBar(UpdateInfo info) {
    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('发现新版本 v${info.latestVersion}'),
        action: SnackBarAction(
          label: '查看',
          onPressed: () {
            _showOptionalUpdateDialog(info);
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showOptionalUpdateDialog(UpdateInfo info) {
    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.blue),
            SizedBox(width: 12),
            Text('发现新版本'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('稍后更新'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final success = await UpdateService.openUpdateUrl(info.updateUrl);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('无法打开下载链接')),
                );
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('立即更新'),
          ),
        ],
      ),
    );
  }

  void _showForceUpdateDialog(UpdateInfo info) {
    if (_hasShownForceUpdate) return;
    _hasShownForceUpdate = true;

    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // 不允许点击外部关闭
      builder: (context) => PopScope(
        canPop: false, // 不允许返回键关闭
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('强制更新'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 重要提示
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '检测到重要更新，需要立即更新才能继续使用',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
              ],
            ),
          ),
          actions: [
            FilledButton.icon(
              onPressed: () async {
                final success = await UpdateService.openUpdateUrl(info.updateUrl);
                // 不关闭对话框，等待用户更新后重启应用
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('无法打开下载链接，请稍后重试')),
                  );
                } else {
                  // 提示用户更新完成后重启应用
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('请下载并安装更新后重启应用'),
                        duration: Duration(seconds: 10),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('立即更新'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          // 获取系统亮度
          final systemBrightness = MediaQuery.platformBrightnessOf(context);
          
          // 根据用户选择决定实际主题
          AppTheme effectiveTheme = appState.currentTheme;
          if (appState.currentTheme == AppTheme.auto) {
            effectiveTheme = systemBrightness == Brightness.dark 
                ? AppTheme.dark 
                : AppTheme.light;
          }
          
          final needsGradient = effectiveTheme == AppTheme.liquidGlass;
          final needsDecorated = effectiveTheme == AppTheme.cute || effectiveTheme == AppTheme.fresh;
          final hasCustomBackground = appState.backgroundImagePath != null;
          
          Widget home = const HomePage();
          
          // 优先使用自定义背景图片
          if (hasCustomBackground) {
            home = CustomBackground(
              imagePath: appState.backgroundImagePath,
              child: home,
            );
          } else if (needsDecorated) {
            // 可爱粉和清新绿主题使用装饰背景
            final themeData = getThemeData(effectiveTheme);
            home = DecoratedBackground(
              backgroundColor: themeData.colorScheme.surface,
              decorationType: effectiveTheme == AppTheme.cute 
                ? DecorationType.catPaws 
                : DecorationType.bamboo,
              child: home,
            );
          } else if (needsGradient) {
            // Liquid Glass 渐变背景
            home = const GradientBackground(child: HomePage());
          }
          
          return MaterialApp(
            title: '即刻清单',
            navigatorKey: _navigatorKey, // 添加 NavigatorKey 以便访问 context
            debugShowCheckedModeBanner: false, // 隐藏右上角的 DEBUG 标志
            theme: getThemeData(effectiveTheme),
            darkTheme: getThemeData(AppTheme.dark),
            themeMode: appState.currentTheme == AppTheme.auto 
                ? ThemeMode.system 
                : ThemeMode.light,
            // 添加中文本地化支持
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh', 'CN'), // 简体中文
              Locale('en', 'US'), // 英文
            ],
            locale: const Locale('zh', 'CN'), // 默认使用简体中文
            home: home,
          );
        },
      ),
    );
  }
}
