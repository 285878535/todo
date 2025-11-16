import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// 背景音乐类型（后续可扩展更多）
enum BgmType {
  none,
  rain,
  bambooRain,
  ocean,
  lightMusic,
  piano,
  heavy_rain
}

/// 统一管理背景音乐与提示音
class AudioService {
  AudioService._internal();
  static final AudioService instance = AudioService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  BgmType _currentBgm = BgmType.lightMusic;
  double _bgmVolume = 0.25;
  double _sfxVolume = 0.6;

  Future<void> init() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      _bgmPlayer.setLoopMode(LoopMode.all);
      _bgmPlayer.setVolume(_bgmVolume);
      _sfxPlayer.setVolume(_sfxVolume);
    } catch (e) {
      if (kDebugMode) {
        print('音频会话初始化失败: $e');
      }
    }
  }

  BgmType get currentBgm => _currentBgm;
  double get bgmVolume => _bgmVolume;
  double get sfxVolume => _sfxVolume;

  Future<void> setBgm(BgmType type) async {
    _currentBgm = type;
    if (type == BgmType.none) {
      await _bgmPlayer.stop();
      return;
    }
    // 预留资源路径（后期只需把对应音频放到 assets/sounds 下）
    final path = switch (type) {
      BgmType.rain => 'assets/sounds/rain.mp3',
      BgmType.bambooRain => 'assets/sounds/bamboo_rain.mp3',
      BgmType.ocean => 'assets/sounds/ocean.mp3',
      BgmType.lightMusic => 'assets/sounds/light_music1.mp3',
      BgmType.piano => 'assets/sounds/piano.mp3',
      BgmType.heavy_rain => 'assets/sounds/heavy_rain.mp3',
      _ => '',
    };
    if (path.isEmpty) {
      await _bgmPlayer.stop();
      return;
    }
    try {
      await _bgmPlayer.setAsset(path);
    } catch (e) {
      if (kDebugMode) {
        print('加载BGM失败: $e');
      }
    }
  }

  Future<void> playBgm() async {
    if (_currentBgm == BgmType.none) return;
    try {
      await _bgmPlayer.play();
    } catch (e) {
      if (kDebugMode) {
        print('播放BGM失败: $e');
      }
    }
  }

  Future<void> pauseBgm() async {
    try {
      await _bgmPlayer.pause();
    } catch (_) {}
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (_) {}
  }

  Future<void> setBgmVolume(double volume) async {
    _bgmVolume = volume.clamp(0.0, 1.0);
    await _bgmPlayer.setVolume(_bgmVolume);
  }

  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _sfxPlayer.setVolume(_sfxVolume);
  }

  /// 播放提示音（如开始、完成）
  Future<void> playSfxStart() => _playSfx('assets/sounds/start.mp3');
  Future<void> playSfxComplete() => _playSfx('assets/sounds/complete.mp3');

  Future<void> _playSfx(String assetPath) async {
    try {
      await _sfxPlayer.setAsset(assetPath);
      await _sfxPlayer.seek(Duration.zero);
      await _sfxPlayer.play();
    } catch (e) {
      if (kDebugMode) {
        print('播放提示音失败: $e');
      }
    }
  }

  Future<void> dispose() async {
    await _bgmPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}


