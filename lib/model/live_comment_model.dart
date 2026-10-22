import 'dart:ui';

class LiveCommentModel {
  final String id;
  final String username;
  final String message;
  final Color avatarColor;
  final bool isHost;
  final DateTime timestamp;

  LiveCommentModel({
    required this.id,
    required this.username,
    required this.message,
    required this.avatarColor,
    this.isHost = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}