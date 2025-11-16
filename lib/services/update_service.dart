import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 更新信息模型
class UpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final int latestBuild;
  final String updateUrl;
  final String releaseNotes;
  final bool forceUpdate;
  final String minVersion;
  final String? fileSize;
  final String? releaseDate;

  UpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.latestBuild,
    required this.updateUrl,
    required this.releaseNotes,
    required this.forceUpdate,
    required this.minVersion,
    this.fileSize,
    this.releaseDate,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return UpdateInfo(
      hasUpdate: data['has_update'] as bool? ?? false,
      latestVersion: data['latest_version'] as String? ?? '',
      latestBuild: data['latest_build'] as int? ?? 0,
      updateUrl: data['update_url'] as String? ?? '',
      releaseNotes: data['release_notes'] as String? ?? '',
      forceUpdate: data['force_update'] as bool? ?? false,
      minVersion: data['min_version'] as String? ?? '',
      fileSize: data['file_size'] as String?,
      releaseDate: data['release_date'] as String?,
    );
  }
}

/// 更新检测异常类型
enum UpdateErrorType {
  network,
  server,
  invalidResponse,
  unknown,
}

class UpdateCheckException implements Exception {
  final UpdateErrorType type;
  final String message;
  final int? statusCode;
  final int? serverCode;

  const UpdateCheckException({
    required this.type,
    required this.message,
    this.statusCode,
    this.serverCode,
  });

  @override
  String toString() => 'UpdateCheckException($type, $message)';
}

/// 更新检测服务
class UpdateService {
  // API 基础地址
  static const String _baseUrl = 'http://api.deepauto.xyz:8123';
  // static const String _baseUrl = 'http://192.168.1.63:8123';
  
  // 检查更新接口
  static const String _checkUpdateEndpoint = '/app/jikeqingdan/check-update';
  
  // 应用 ID（对应 Android 的 applicationId 和 iOS 的 Bundle ID）
  static const String _appId = 'com.example.todo';
  
  // 超时时间
  static const Duration _timeout = Duration(seconds: 10);

  /// 通过远程静态清单文件（例如 GitHub Raw 或自建服务器上的 version.json）检查更新
  ///
  /// - manifestUrl: 远程清单文件完整 URL（建议 HTTPS）
  /// - 清单格式支持两类：
  ///   1) 扁平结构：
  ///      {
  ///        "latest_version": "1.2.3",
  ///        "latest_build": 5,
  ///        "update_url": "https://example.com/app.apk",
  ///        "release_notes": "修复问题",
  ///        "force_update": false,
  ///        "min_version": "1.0.0",
  ///        "file_size": "25 MB",
  ///        "release_date": "2025-11-16"
  ///      }
  ///   2) data 包裹结构：
  ///      { "code": 200, "data": { ...同上... } }
  static Future<UpdateInfo> checkUpdateFromManifest(String manifestUrl) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final buildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      final resp = await http.get(Uri.parse(manifestUrl)).timeout(_timeout);
      if (resp.statusCode != 200) {
        throw UpdateCheckException(
          type: UpdateErrorType.server,
          message: '拉取清单失败，状态码 ${resp.statusCode}',
          statusCode: resp.statusCode,
        );
      }
      final jsonObj = jsonDecode(utf8.decode(resp.bodyBytes));
      if (jsonObj is! Map<String, dynamic>) {
        throw const UpdateCheckException(
          type: UpdateErrorType.invalidResponse,
          message: '清单文件格式不正确',
        );
      }
      final Map<String, dynamic> data =
          (jsonObj['data'] is Map<String, dynamic>) ? jsonObj['data'] as Map<String, dynamic> : jsonObj;

      final latestVersion = data['latest_version'] as String? ?? '';
      final latestBuild = data['latest_build'] as int? ?? 0;
      final updateUrl = data['update_url'] as String? ?? '';
      final releaseNotes = data['release_notes'] as String? ?? '';
      final forceUpdate = data['force_update'] as bool? ?? false;
      final minVersion = data['min_version'] as String? ?? '';
      final fileSize = data['file_size'] as String?;
      final releaseDate = data['release_date'] as String?;

      final needByVersion = compareVersion(latestVersion, currentVersion) > 0;
      final needByBuild = latestBuild > buildNumber;

      return UpdateInfo(
        hasUpdate: needByVersion || needByBuild,
        latestVersion: latestVersion,
        latestBuild: latestBuild,
        updateUrl: updateUrl,
        releaseNotes: releaseNotes,
        forceUpdate: forceUpdate,
        minVersion: minVersion,
        fileSize: fileSize,
        releaseDate: releaseDate,
      );
    } on SocketException catch (_) {
      throw const UpdateCheckException(
        type: UpdateErrorType.network,
        message: '无法连接更新清单，请检查网络连接',
      );
    } on TimeoutException catch (_) {
      throw const UpdateCheckException(
        type: UpdateErrorType.network,
        message: '连接更新清单超时，请稍后重试',
      );
    } on FormatException catch (_) {
      throw const UpdateCheckException(
        type: UpdateErrorType.invalidResponse,
        message: '清单文件不是有效的 JSON',
      );
    } on UpdateCheckException {
      rethrow;
    } catch (e) {
      throw UpdateCheckException(
        type: UpdateErrorType.unknown,
        message: '解析更新清单失败: $e',
      );
    }
  }
  /// 检查更新
  /// 
  /// 返回 UpdateInfo 对象，失败时抛出 UpdateCheckException
  static Future<UpdateInfo> checkUpdate() async {
    try {
      // 获取当前应用信息
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final buildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;
      
      // 获取平台信息
      String platform = 'unknown';
      if (Platform.isAndroid) {
        platform = 'android';
      } else if (Platform.isIOS) {
        platform = 'ios';
      } else if (Platform.isMacOS) {
        platform = 'macos';
      }

      // 构建请求参数
      final requestBody = {
        'app_id': _appId,
        'current_version': currentVersion,
        'platform': platform,
        'build_number': buildNumber,
      };

      // 发送 POST 请求
      final response = await http
          .post(
            Uri.parse('$_baseUrl$_checkUpdateEndpoint'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw UpdateCheckException(
          type: UpdateErrorType.server,
          message: '服务器返回异常状态码 ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final jsonData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final int? serverCode = jsonData['code'] as int?;

      if (serverCode == 200) {
        return UpdateInfo.fromJson(jsonData);
      } else {
        throw UpdateCheckException(
          type: UpdateErrorType.server,
          message: jsonData['message'] as String? ?? '服务器返回错误',
          serverCode: serverCode,
        );
      }
    } on SocketException catch (_) {
      throw UpdateCheckException(
        type: UpdateErrorType.network,
        message: '无法连接更新服务器，请检查网络连接',
      );
    } on TimeoutException catch (_) {
      throw const UpdateCheckException(
        type: UpdateErrorType.network,
        message: '连接更新服务器超时，请稍后重试',
      );
    } on FormatException catch (_) {
      throw const UpdateCheckException(
        type: UpdateErrorType.invalidResponse,
        message: '服务器返回了无法解析的数据',
      );
    } on UpdateCheckException {
      rethrow;
    } catch (e) {
      throw UpdateCheckException(
        type: UpdateErrorType.unknown,
        message: '检查更新时发生未知错误: $e',
      );
    }
  }

  /// 打开更新下载页面
  /// 
  /// 在浏览器中打开下载链接
  static Future<bool> openUpdateUrl(String url) async {
    try {
      // 规范化 URL（若缺少 scheme，默认 https）
      final normalized = url.trim();
      final uri = Uri.parse(
        (normalized.startsWith('http://') || normalized.startsWith('https://'))
            ? normalized
            : 'https://$normalized',
      );

      // 优先尝试外部浏览器
      final openedExternal = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (openedExternal) return true;

      // 回退为平台默认方式
      final openedDefault = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      if (openedDefault) return true;

      // 再回退为内置 WebView（若可用）
      final openedInApp = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      return openedInApp;
    } catch (e) {
      print('打开更新链接失败: $e');
      return false;
    }
  }

  /// 比较版本号
  /// 
  /// 返回值：
  /// - 1: version1 > version2
  /// - 0: version1 == version2
  /// - -1: version1 < version2
  static int compareVersion(String version1, String version2) {
    final v1Parts = version1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2Parts = version2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    final maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;
    
    for (int i = 0; i < maxLength; i++) {
      final v1 = i < v1Parts.length ? v1Parts[i] : 0;
      final v2 = i < v2Parts.length ? v2Parts[i] : 0;
      
      if (v1 > v2) return 1;
      if (v1 < v2) return -1;
    }
    
    return 0;
  }
}

