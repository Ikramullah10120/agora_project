import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_project/stream_log_entry.dart';

/// On-screen Diagnostics & Log viewer sheet
class DiagnosticsSheet extends StatelessWidget {
  final List<StreamLogEntry> logs;
  final String channelName;
  final bool isHost;
  final String username;
  final String appId;
  final String token;
  final String connectionStateStr;
  final int? dataStreamId;
  final bool chatLoggedIn;
  final VoidCallback onClearLogs;

  const DiagnosticsSheet({
    super.key,
    required this.logs,
    required this.channelName,
    required this.isHost,
    required this.username,
    required this.appId,
    required this.token,
    required this.connectionStateStr,
    required this.dataStreamId,
    required this.chatLoggedIn,
    required this.onClearLogs,
  });

  void _copyAllLogs(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln("════════ AGORA LIVE STREAM DIAGNOSTIC REPORT ════════");
    buffer.writeln(
      "Channel: $channelName | Role: ${isHost ? 'Host' : 'Audience'} | User: $username",
    );
    buffer.writeln("AppID: $appId");
    buffer.writeln("Token Length: ${token.length}");
    buffer.writeln("Connection State: $connectionStateStr");
    buffer.writeln("DataStream ID: ${dataStreamId ?? 'None (Unavailable)'}");
    buffer.writeln("Chat Logged In: $chatLoggedIn");
    buffer.writeln("═════════════════════════════════════════════════════\n");

    for (final log in logs) {
      buffer.writeln(log.toClipboardString());
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All logs copied to clipboard!')),
    );
  }

  Color _levelColor(LogLevel level) {
    switch (level) {
      case LogLevel.success:
        return const Color(0xFF4CAF50);
      case LogLevel.warning:
        return const Color(0xFFFF9800);
      case LogLevel.error:
        return const Color(0xFFF44336);
      case LogLevel.info:
        return const Color(0xFF29B6F6);
    }
  }

  IconData _levelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.success:
        return Icons.check_circle_outline;
      case LogLevel.warning:
        return Icons.warning_amber_rounded;
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF14141E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.troubleshoot,
                  color: Colors.purpleAccent,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Feature Diagnostics & Logs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Copy all logs to clipboard',
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () => _copyAllLogs(context),
                ),
                IconButton(
                  tooltip: 'Clear logs',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: onClearLogs,
                ),
              ],
            ),
          ),

          // Feature Status Grid / Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              children: [
                Expanded(
                  child: _StatusCard(
                    title: 'RTC State',
                    value: connectionStateStr,
                    isSuccess:
                        connectionStateStr.toLowerCase().contains('join') ||
                        connectionStateStr.toLowerCase().contains('connect'),
                    icon: Icons.videocam,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusCard(
                    title: 'Role',
                    value: isHost ? 'Host (Broadcaster)' : 'Viewer (Audience)',
                    isSuccess: true,
                    icon: isHost ? Icons.record_voice_over : Icons.visibility,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              children: [
                Expanded(
                  child: _StatusCard(
                    title: 'Comments DataStream',
                    value: dataStreamId != null
                        ? 'ID: $dataStreamId (Active)'
                        : (isHost ? 'Creating...' : 'Blocked (Audience)'),
                    isSuccess: dataStreamId != null,
                    icon: Icons.comment,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusCard(
                    title: 'Agora Chat SDK',
                    value: chatLoggedIn
                        ? 'Logged In ($username)'
                        : 'Not Logged In',
                    isSuccess: chatLoggedIn,
                    icon: Icons.chat_bubble_outline,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),

          // Logs List Title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Text(
                  'Event Log History (${logs.length})',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Tap "Copy" above to note down',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

          // Logs List
          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs captured yet.',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: logs.length,
                    itemBuilder: (ctx, i) {
                      final log =
                          logs[logs.length - 1 - i]; // Most recent first
                      final color = _levelColor(log.level);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C),
                          borderRadius: BorderRadius.circular(10),
                          border: Border(
                            left: BorderSide(color: color, width: 3.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _levelIcon(log.level),
                                  color: color,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    log.feature,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  log.formattedTime(),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              log.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                            if (log.params != null &&
                                log.params!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'INPUTS / PARAMETERS:',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...log.params!.entries.map(
                                      (entry) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 2.0,
                                        ),
                                        child: SelectableText(
                                          '• ${entry.key}: ${entry.value}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isSuccess;
  final IconData icon;

  const _StatusCard({
    required this.title,
    required this.value,
    required this.isSuccess,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSuccess
              ? Colors.greenAccent.withValues(alpha: 0.3)
              : Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSuccess ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSuccess ? Colors.white : Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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
