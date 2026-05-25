import 'package:flutter/material.dart';

/// Animated page transition routes
class AnimatedPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  AnimatedPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade + Slide up animation
            const begin = Offset(0.0, 0.3);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end);
            final offsetAnimation = animation.drive(tween);

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Page transition for modal-style (upward slide)
class ModalPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  ModalPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide from bottom
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end);
            final offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
}

/// Extension for easy navigation
extension NavigationExt on BuildContext {
  Future<T?> pushAnimatedPage<T>(Widget page) {
    return Navigator.of(this).push<T>(AnimatedPageRoute(page: page));
  }

  Future<T?> pushModalPage<T>(Widget page) {
    return Navigator.of(this).push<T>(ModalPageRoute(page: page));
  }
}
