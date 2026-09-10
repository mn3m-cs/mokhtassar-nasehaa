import 'dart:math' as math;

import 'package:flutter/material.dart';

class ShakeTutorialDialog extends StatelessWidget {
  const ShakeTutorialDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnimatedShakeIllustration(),
            const SizedBox(height: 20),
            Text(
              "ميزة جديدة: هز الهاتف للإبلاغ",
              style: TextStyle(
                fontFamily: "Cairo",
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            Text(
              "إذا لاحظت أي خطأ إملائي أو مطبعي في الأذكار، يمكنك الآن ببساطة هز الهاتف في أي وقت أثناء القراءة.\n\nستظهر لك نافذة تتيح لك كتابة الخطأ وإرساله لنا مباشرة لنقوم بتعديله.",
              style: TextStyle(
                fontFamily: "Cairo",
                fontSize: 14,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.8),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                ),
                child: const Text(
                  "فهمت",
                  style: TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedShakeIllustration extends StatefulWidget {
  const AnimatedShakeIllustration({super.key});

  @override
  State<AnimatedShakeIllustration> createState() =>
      _AnimatedShakeIllustrationState();
}

class _AnimatedShakeIllustrationState extends State<AnimatedShakeIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shakeAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // Shake animation: rotates left and right quickly, then pauses
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: 0.0), weight: 1),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 7), // Pause duration
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Pulse animation for the background ripples
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 160,
      width: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background pulses
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double value = _pulseAnimation.value;
              final double opacity = math.max(0.0, 1.0 - (value - 0.8) / 0.5);
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 110 * value,
                    height: 110 * value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: opacity * 0.15),
                    ),
                  ),
                  Container(
                    width: 130 * value,
                    height: 130 * value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: opacity * 0.05),
                    ),
                  ),
                ],
              );
            },
          ),
          // Shaking Phone
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _shakeAnimation.value,
                child: child,
              );
            },
            child: Container(
              width: 70,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.8),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Screen bezel details
                  Positioned(
                    top: 8,
                    child: Container(
                      width: 25,
                      height: 4,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // App layout mock
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 18.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                            height: 6,
                            color: primaryColor.withValues(alpha: 0.2)),
                        Container(
                            height: 6,
                            color: primaryColor.withValues(alpha: 0.2)),
                        Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.report_problem_outlined,
                            size: 16,
                            color: primaryColor,
                          ),
                        ),
                        Container(
                            height: 6,
                            color: primaryColor.withValues(alpha: 0.2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Wave lines to indicate shake
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              final isMoving = _shakeAnimation.value.abs() > 0.02;
              return AnimatedOpacity(
                opacity: isMoving ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: child,
              );
            },
            child: Stack(
              children: [
                Positioned(
                  left: 20,
                  top: 65,
                  child: Icon(Icons.waves,
                      color: primaryColor.withValues(alpha: 0.6), size: 24),
                ),
                Positioned(
                  right: 20,
                  top: 65,
                  child: Transform.rotate(
                    angle: math.pi,
                    child: Icon(Icons.waves,
                        color: primaryColor.withValues(alpha: 0.6), size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
