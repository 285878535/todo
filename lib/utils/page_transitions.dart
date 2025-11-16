import 'package:flutter/material.dart';

/// 自定义页面转场动画 - 淡入淡出效果（支持右滑返回）
/// 避免半透明页面在转场时出现重叠
class FadePageRoute<T> extends PageRoute<T> {
  final Widget page;
  
  FadePageRoute({required this.page});

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return page;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  // 启用 iOS 风格的右滑返回手势
  @override
  bool get popGestureEnabled => true;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => false;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => false;
}

/// 缩放+淡入效果的页面转场（支持右滑返回）
class ScaleFadePageRoute<T> extends PageRoute<T> {
  final Widget page;
  
  ScaleFadePageRoute({required this.page});

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return page;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    const begin = 0.95;
    const end = 1.0;
    final scaleTween = Tween(begin: begin, end: end);
    final scaleAnimation = animation.drive(scaleTween);
    
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: child,
      ),
    );
  }

  // 启用 iOS 风格的右滑返回手势
  @override
  bool get popGestureEnabled => true;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => false;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => false;
}

/// iOS 风格的页面转场 - 从底部弹出（支持下滑关闭）
class IOSModalPageRoute<T> extends PageRoute<T> {
  final Widget page;
  
  IOSModalPageRoute({required this.page});

  @override
  Color? get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 350);

  @override
  bool get barrierDismissible => false;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return page;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;
    
    final slideTween = Tween(begin: begin, end: end);
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );
    
    return SlideTransition(
      position: slideTween.animate(curvedAnimation),
      child: child,
    );
  }

  // 启用下滑关闭手势
  @override
  bool get popGestureEnabled => true;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => false;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => false;
}

