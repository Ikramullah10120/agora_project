/// Log severity level
enum LogLevel { info, success, warning, error }

/// Represents a diagnostic log entry for tracking features and their inputs
class StreamLogEntry {
  final DateTime timestamp;
  final String feature;
  final String message;
  final Map<String, dynamic>? params;
  final LogLevel level;

  StreamLogEntry({
    required this.feature,
    required this.message,
    this.params,
    this.level = LogLevel.info,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String formattedTime() {
    return "${timestamp.hour.toString().padLeft(2, '0')}:"
        "${timestamp.minute.toString().padLeft(2, '0')}:"
        "${timestamp.second.toString().padLeft(2, '0')}";
  }

  String toClipboardString() {
    final buffer = StringBuffer();
    buffer.writeln(
      "[${formattedTime()}] [${level.name.toUpperCase()}] [$feature] $message",
    );
    if (params != null && params!.isNotEmpty) {
      params!.forEach((k, v) => buffer.writeln("    • $k: $v"));
    }
    return buffer.toString();
  }
}
