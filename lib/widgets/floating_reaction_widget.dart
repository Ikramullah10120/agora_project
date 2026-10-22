
import 'package:flutter/material.dart';

/// Floating reaction item (heart, fire, etc.)
class FloatingReaction {
  final String id;
  final double startX;
  final Color color;
  final IconData icon;

  FloatingReaction({
    required this.id,
    required this.startX,
    required this.color,
    this.icon = Icons.favorite,
  });
}