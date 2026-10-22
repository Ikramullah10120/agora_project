import 'package:flutter/material.dart';
import 'package:agora_project/model/live_comment_model.dart';

/// Overlay widget that shows the live comments stream with Instagram styling
class LiveCommentsListWidget extends StatelessWidget {
  final List<LiveCommentModel> comments;
  final ScrollController scrollController;

  const LiveCommentsListWidget({
    super.key,
    required this.comments,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.white, Colors.white],
          stops: [0.0, 0.22, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        itemCount: comments.length,
        itemBuilder: (context, index) {
          final comment = comments[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: comment.avatarColor,
                  child: Text(
                    comment.username.isNotEmpty
                        ? comment.username[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${comment.username} ',
                            style: TextStyle(
                              color: comment.isHost
                                  ? const Color(0xFFFFD54F)
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (comment.isHost)
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: EdgeInsets.only(right: 4.0),
                                child: Icon(
                                  Icons.star,
                                  color: Color(0xFFFFD54F),
                                  size: 12,
                                ),
                              ),
                            ),
                          TextSpan(
                            text: comment.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
