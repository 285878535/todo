import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 带装饰图案的背景（可爱粉主题的猫爪子、清新绿主题的竹子）
class DecoratedBackground extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final DecorationType decorationType;

  const DecoratedBackground({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.decorationType,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景色
        Container(color: backgroundColor),
        // 装饰图案
        Positioned.fill(
          child: CustomPaint(
            painter: decorationType == DecorationType.catPaws
                ? _CatPawsPainter()
                : _BambooPainter(),
          ),
        ),
        // 实际内容
        child,
      ],
    );
  }
}

enum DecorationType {
  catPaws,
  bamboo,
}

/// 猫爪子图案绘制器
class _CatPawsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB6C1).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // 固定种子，保证图案一致

    // 绘制约 20 个猫爪子
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final scale = 0.8 + random.nextDouble() * 0.4; // 0.8-1.2 倍大小
      final rotation = random.nextDouble() * math.pi * 2;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.scale(scale);
      
      _drawCatPaw(canvas, paint);
      
      canvas.restore();
    }
  }

  void _drawCatPaw(Canvas canvas, Paint paint) {
    // 主肉垫（大的）
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 6), width: 18, height: 20),
      paint,
    );

    // 四个小肉垫
    canvas.drawCircle(const Offset(-8, -2), 5, paint); // 左上
    canvas.drawCircle(const Offset(-3, -6), 5, paint); // 中左
    canvas.drawCircle(const Offset(3, -6), 5, paint);  // 中右
    canvas.drawCircle(const Offset(8, -2), 5, paint);  // 右上
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 竹子图案绘制器
class _BambooPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF81C784).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()
      ..color = const Color(0xFF81C784).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final random = math.Random(123); // 固定种子

    // 绘制约 15 根竹子
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * (size.height * 0.5); // 只在上半部分
      final height = 80 + random.nextDouble() * 60; // 80-140 高度
      final rotation = -0.2 + random.nextDouble() * 0.4; // 轻微倾斜

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      
      _drawBamboo(canvas, paint, leafPaint, height);
      
      canvas.restore();
    }
  }

  void _drawBamboo(Canvas canvas, Paint paint, Paint leafPaint, double height) {
    // 竹竿
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, height);
    canvas.drawPath(path, paint);

    // 竹节（3-4个节）
    final segments = 3 + (height ~/ 40).clamp(0, 2);
    for (int i = 1; i <= segments; i++) {
      final y = (height / (segments + 1)) * i;
      canvas.drawLine(
        Offset(-4, y),
        Offset(4, y),
        paint..strokeWidth = 2,
      );
    }

    // 竹叶（2-3片）
    final leaves = 2 + (height ~/ 50).clamp(0, 1);
    for (int i = 0; i < leaves; i++) {
      final y = (height / (leaves + 1)) * (i + 1);
      _drawLeaf(canvas, leafPaint, Offset(0, y), true);
      _drawLeaf(canvas, leafPaint, Offset(0, y + 5), false);
    }
  }

  void _drawLeaf(Canvas canvas, Paint paint, Offset position, bool isRight) {
    final leafPath = Path();
    final direction = isRight ? 1 : -1;
    
    leafPath.moveTo(position.dx, position.dy);
    leafPath.quadraticBezierTo(
      position.dx + direction * 15,
      position.dy - 3,
      position.dx + direction * 25,
      position.dy - 8,
    );
    leafPath.quadraticBezierTo(
      position.dx + direction * 15,
      position.dy - 5,
      position.dx,
      position.dy,
    );
    
    canvas.drawPath(leafPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

