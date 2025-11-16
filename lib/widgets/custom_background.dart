import 'dart:io';
import 'package:flutter/material.dart';

/// 自定义背景组件 - 可显示图片或渐变背景
class CustomBackground extends StatelessWidget {
  final Widget child;
  final String? imagePath;
  final bool useGradient;
  
  const CustomBackground({
    super.key,
    required this.child,
    this.imagePath,
    this.useGradient = false,
  });
  
  @override
  Widget build(BuildContext context) {
    // 如果有自定义背景图片，显示图片
    if (imagePath != null && imagePath!.isNotEmpty) {
      final file = File(imagePath!);
      if (file.existsSync()) {
        return Stack(
          children: [
            // 背景图片
            Positioned.fill(
              child: Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // 如果图片加载失败，显示默认背景
                  return _buildDefaultBackground(context);
                },
              ),
            ),
            // 半透明遮罩层，让内容更清晰
            Positioned.fill(
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
            // 内容
            child,
          ],
        );
      }
    }
    
    // 如果需要渐变背景
    if (useGradient) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F2FE), // Light blue - iOS 风格天空蓝
              Color(0xFFFCE7F3), // Light pink - 温馨粉色
              Color(0xFFDDD6FE), // Light purple - 优雅紫色
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: child,
      );
    }
    
    // 默认不使用背景
    return child;
  }
  
  Widget _buildDefaultBackground(BuildContext context) {
    if (useGradient) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F2FE),
              Color(0xFFFCE7F3),
              Color(0xFFDDD6FE),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      );
    }
    return Container(color: Theme.of(context).scaffoldBackgroundColor);
  }
}

