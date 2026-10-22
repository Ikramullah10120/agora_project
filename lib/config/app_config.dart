import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration class managing Agora credentials and secrets.
/// Loads values securely from .env and compile-time `--dart-define` parameters.
class AppConfig {
  AppConfig._();

  static bool _initialized = false;

  /// Initialize environment configuration.
  /// Safely attempts to load `.env` if available, falling back to compile-time
  /// environment definitions (`--dart-define` / `--dart-define-from-file`).
  static Future<void> init() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: ".env");
      if (kDebugMode) {
        debugPrint("[AppConfig] Successfully loaded .env file");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          "[AppConfig] Notice: .env file could not be loaded ($e). Falling back to environment variables.",
        );
      }
    }

    _initialized = true;
  }

  /// Agora App ID
  static String get appId {
    final value = dotenv.maybeGet('AGORA_APP_ID');
    if (value != null && value.isNotEmpty) return value;
    return const String.fromEnvironment('AGORA_APP_ID', defaultValue: '');
  }

  /// Agora Chat App Key (Format: `<OrgName>#<AppName>`)
  static String get chatAppKey {
    final value = dotenv.maybeGet('AGORA_CHAT_APP_KEY');
    if (value != null && value.isNotEmpty) return value;
    return const String.fromEnvironment(
      'AGORA_CHAT_APP_KEY',
      defaultValue: '',
    );
  }

  /// Default User ID
  static String get userId {
    final value = dotenv.maybeGet('AGORA_USER_ID');
    if (value != null && value.isNotEmpty) return value;
    return const String.fromEnvironment('AGORA_USER_ID', defaultValue: 'user1');
  }

  /// Agora RTC Dynamic Token (Temporary / Dev token)
  /// Note: In production, tokens should be dynamically generated via a secure backend.
  static String get token {
    final value = dotenv.maybeGet('AGORA_RTC_TOKEN');
    if (value != null && value.isNotEmpty) return value;
    return const String.fromEnvironment('AGORA_RTC_TOKEN', defaultValue: '');
  }

  /// Agora Chat Token (Temporary / Dev token)
  static String get chatToken {
    final value = dotenv.maybeGet('AGORA_CHAT_TOKEN');
    if (value != null && value.isNotEmpty) return value;
    return const String.fromEnvironment('AGORA_CHAT_TOKEN', defaultValue: '');
  }

  /// Backend Token Server Base URL (Optional, for production architecture)
  static String get tokenServerUrl {
    final value = dotenv.maybeGet('AGORA_TOKEN_SERVER_URL');
    if (value != null && value.isNotEmpty) return value;
    return const String.fromEnvironment(
      'AGORA_TOKEN_SERVER_URL',
      defaultValue: '',
    );
  }

  /// Returns true if a secure backend token server is configured.
  static bool get hasTokenServer => tokenServerUrl.trim().isNotEmpty;

  /// Returns true if Agora App ID is provided.
  static bool get isConfigured =>
      appId.isNotEmpty && appId != 'YOUR_AGORA_APP_ID';

  /// Masked App ID for safe display in diagnostics and logs without exposing raw credentials.
  static String get maskedAppId {
    if (appId.length <= 8) return '****';
    return '${appId.substring(0, 4)}...${appId.substring(appId.length - 4)}';
  }

  /// Masked token string for safe diagnostic display.
  static String maskSecret(String secret) {
    if (secret.isEmpty) return '(Not set)';
    if (secret.length <= 12) return '******';
    return '${secret.substring(0, 6)}...${secret.substring(secret.length - 6)} (${secret.length} chars)';
  }
}
