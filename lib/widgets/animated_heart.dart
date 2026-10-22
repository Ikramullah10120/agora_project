import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:agora_project/widgets/floating_reaction_widget.dart';

/// Floating animated heart/reaction widget
class AnimatedHeartWidget extends StatefulWidget {
  final FloatingReaction reaction;
  final VoidCallback onComplete;

  const AnimatedHeartWidget({
    super.key,
    required this.reaction,
    required this.onComplete,
  });

  @override
  State<AnimatedHeartWidget> createState() => _AnimatedHeartWidgetState();
}

class _AnimatedHeartWidgetState extends State<AnimatedHeartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateY;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late double _randomWobble;

  @override
  void initState() {
    super.initState();
    _randomWobble = (math.Random().nextDouble() - 0.5) * 40;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1800 + math.Random().nextInt(600)),
    );

    _translateY = Tween<double>(
      begin: 0.0,
      end: -350.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.3), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 60),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final startXPos = screenWidth * widget.reaction.startX;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentWobble =
            math.sin(_controller.value * math.pi * 2) * _randomWobble;

        return Positioned(
          left: startXPos + currentWobble,
          bottom: 70 - _translateY.value,
          child: Opacity(
            opacity: _opacity.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: _scale.value,
              child: Icon(
                widget.reaction.icon,
                color: widget.reaction.color,
                size: 28,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
