import 'package:flutter/material.dart';

/// Bottom bar for adding comments and sending heart/fire reactions
class LiveBottomBarWidget extends StatelessWidget {
  final TextEditingController commentController;
  final bool hasInputText;
  final VoidCallback onSendComment;
  final VoidCallback onFireReaction;
  final VoidCallback onHeartReaction;

  const LiveBottomBarWidget({
    super.key,
    required this.commentController,
    required this.hasInputText,
    required this.onSendComment,
    required this.onFireReaction,
    required this.onHeartReaction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Comment text field
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: commentController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: Colors.white60, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => onSendComment(),
                  ),
                ),
                if (hasInputText)
                  GestureDetector(
                    onTap: onSendComment,
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3897F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Fire reaction button
        GestureDetector(
          onTap: onFireReaction,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 20)),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Heart reaction button
        GestureDetector(
          onTap: onHeartReaction,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF0844), Color(0xFFFFB199)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF0844).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}
