import 'package:flutter/material.dart';

/// Liquid Glass 风格的渐变背景
/// 用于所有页面的统一背景效果
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
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
}

