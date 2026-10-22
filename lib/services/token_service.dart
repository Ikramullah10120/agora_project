import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:agora_project/config/app_config.dart';

/// Secure Token Service for Agora RTC and Chat.
///
/// In a production mobile architecture, private keys and App Certificates must
/// NEVER be stored on the client. Instead, dynamic tokens are requested from
/// an authenticated backend server.
class TokenService {
  TokenService._();

  static final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);

  /// Fetches an RTC token from the backend token server.
  /// Falls back to [AppConfig.token] if no token server URL is configured.
  static Future<String> getRtcToken({
    required String channelName,
    required String uid,
    String role = 'publisher', // 'publisher' or 'subscriber'
  }) async {
    // If no backend URL configured, return development token from .env
    if (!AppConfig.hasTokenServer) {
      return AppConfig.token;
    }

    try {
      final baseUrl = AppConfig.tokenServerUrl.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse(
        '$baseUrl/api/rtc-token?channelName=${Uri.encodeComponent(channelName)}&uid=${Uri.encodeComponent(uid)}&role=$role',
      );

      final request = await _httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token != null && token.isNotEmpty) {
          return token;
        }
      }
      if (kDebugMode) {
        debugPrint(
          '[TokenService] Token server responded with HTTP ${response.statusCode}, falling back to local token.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TokenService] Error fetching RTC token: $e');
      }
    }

    // Fallback to local .env token
    return AppConfig.token;
  }

  /// Fetches an Agora Chat token from the backend server.
  /// Falls back to [AppConfig.chatToken] if no token server URL is configured.
  static Future<String> getChatToken({required String userId}) async {
    if (!AppConfig.hasTokenServer) {
      return AppConfig.chatToken;
    }

    try {
      final baseUrl = AppConfig.tokenServerUrl.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse(
        '$baseUrl/api/chat-token?userId=${Uri.encodeComponent(userId)}',
      );

      final request = await _httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token != null && token.isNotEmpty) {
          return token;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TokenService] Error fetching Chat token: $e');
      }
    }

    return AppConfig.chatToken;
  }
}
