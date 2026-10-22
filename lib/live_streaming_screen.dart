import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart' hide LogLevel;
import 'package:agora_chat_sdk/agora_chat_sdk.dart';

import 'package:agora_project/widgets/floating_reaction_widget.dart';
import 'package:agora_project/model/live_comment_model.dart';
import 'package:agora_project/stream_log_entry.dart';
import 'package:agora_project/widgets/animated_heart.dart';
import 'package:agora_project/widgets/diagnostics_sheet.dart';
import 'package:agora_project/widgets/host_controls.dart';
import 'package:agora_project/widgets/live_bottom_bar.dart';
import 'package:agora_project/widgets/live_comments_list.dart';
import 'package:agora_project/widgets/live_top_bar.dart';

class LiveStreamingScreen extends StatefulWidget {
  final bool isHost;
  final String channelName;
  final String username;

  const LiveStreamingScreen({
    super.key,
    this.isHost = true,
    this.channelName = "Test",
    this.username = "frank",
  });

  @override
  State<LiveStreamingScreen> createState() => _LiveStreamingScreenState();
}

class _LiveStreamingScreenState extends State<LiveStreamingScreen> {
  // Agora App Configuration
  final String appId = "b532b13ca4da47bb9bed248c3dda673f";
  final String chatAppKey = "41200080941#200113715";
  final String userId = "user1";

  // Tokens
  final String chatToken =
      "007eJxTYLAtjls/y6v/dOIn22Wf34lYmF6s9v7o2s36q+dM65d+/uRbgSHJ1NgoydA4OdEkJdHEPCnJMik1xcjEItk4JSXRxDzNOU/4fG336I1A/653MzAwsDIwMjAygvA/MBiAgAEAU4kjfA==";
  final String token =
      "007eJxTYEhZ+DJhj1VUdNq/K/O60s4u931xiXFlyewYQ+evRhkyunsUGJJMjY2SDI2TE01SEk3Mk5Isk1JTjEwsko1TUhLNzI3TVghez2oIZGTQ5nBiZGSAQBCfhSEktbiEgQEAon0fyQ==";

  // RTC Engine state
  RtcEngine? _engine;
  int? _dataStreamId;
  bool _isEngineReady = false;
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _isMuted = false;
  int _viewerCount = 1;
  String? _agoraErrorMessage;
  String _connectionStateStr = "Connecting";
  bool _chatLoggedIn = false;

  // Diagnostics logs
  final List<StreamLogEntry> _logs = [];

  // Comments & Reactions
  final List<LiveCommentModel> _comments = [];
  final List<FloatingReaction> _reactions = [];
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final math.Random _random = math.Random();
  bool _hasInputText = false;

  final List<Color> _avatarColors = const [
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF673AB7),
    Color(0xFF2196F3),
    Color(0xFF009688),
    Color(0xFFFF9800),
    Color(0xFFFF5722),
  ];

  final List<Color> _heartColors = const [
    Color(0xFFFF1744),
    Color(0xFFFF4081),
    Color(0xFFE040FB),
    Color(0xFFFF5252),
    Color(0xFFFF6E40),
    Color(0xFFFFD700),
  ];

  /// Record important diagnostic events without debugPrint clutter
  void _log(
    String feature,
    String message, {
    Map<String, dynamic>? params,
    LogLevel level = LogLevel.info,
  }) {
    final entry = StreamLogEntry(
      feature: feature,
      message: message,
      params: params,
      level: level,
    );

    if (mounted) {
      setState(() => _logs.add(entry));
    } else {
      _logs.add(entry);
    }
  }

  @override
  void initState() {
    super.initState();

    _log(
      "Session Init",
      "Screen launched for ${widget.isHost ? 'Host' : 'Audience'}",
      params: {
        'channel': widget.channelName,
        'user': widget.username,
        'appId': appId,
      },
    );

    _commentController.addListener(() {
      final hasText = _commentController.text.trim().isNotEmpty;
      if (hasText != _hasInputText) {
        setState(() => _hasInputText = hasText);
      }
    });

    _comments.add(
      LiveCommentModel(
        id: 'system_welcome',
        username: 'System',
        message: widget.isHost
            ? 'You are live! Comments will appear here.'
            : 'Welcome to the live stream! Say hi 👋',
        avatarColor: Colors.deepPurple,
      ),
    );

    _initAgora();
  }

  Future<void> _initAgora() async {
    // 1. Request camera and mic permissions if host
    if (widget.isHost) {
      final statuses = await [
        Permission.microphone,
        Permission.camera,
      ].request();

      final camGranted =
          statuses[Permission.camera] == PermissionStatus.granted;
      final micGranted =
          statuses[Permission.microphone] == PermissionStatus.granted;

      if (!camGranted || !micGranted) {
        _log(
          "Permissions",
          "Camera/Mic permissions denied",
          level: LogLevel.error,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera and Microphone permissions are required.'),
            ),
          );
        }
        return;
      }
    }

    // 2. Initialize RtcEngine
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );
      _log("RTC Engine", "Initialized successfully", level: LogLevel.success);
    } catch (e) {
      _log("RTC Engine", "Init failed: $e", level: LogLevel.error);
      return;
    }

    // 3. Register Event Handlers
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
          _log(
            "Channel Join",
            "Joined channel: ${connection.channelId}",
            params: {'uid': connection.localUid},
            level: LogLevel.success,
          );

          if (mounted) {
            setState(() {
              _localUserJoined = true;
              _connectionStateStr = "Joined";
            });
          }

          // Create Data Stream for real-time live comments
          try {
            final streamId = await _engine!.createDataStream(
              const DataStreamConfig(syncWithAudio: false, ordered: true),
            );
            _dataStreamId = streamId;
            _log(
              "Data Stream",
              "Created stream ID: $streamId",
              level: LogLevel.success,
            );
          } catch (e) {
            _log(
              "Data Stream",
              "Failed: $e (Audience cannot send stream messages in RTC)",
              level: LogLevel.warning,
            );
          }
        },

        onConnectionStateChanged:
            (
              RtcConnection connection,
              ConnectionStateType state,
              ConnectionChangedReasonType reason,
            ) {
              final isFail = state == ConnectionStateType.connectionStateFailed;
              final isConnected =
                  state == ConnectionStateType.connectionStateConnected;

              _log(
                "Connection State",
                "${state.name} (${reason.name})",
                params: {'state': state.name, 'reason': reason.name},
                level: isFail
                    ? LogLevel.error
                    : (isConnected ? LogLevel.success : LogLevel.info),
              );

              if (mounted) {
                setState(() {
                  _connectionStateStr = "${state.name} (${reason.name})";
                });
              }
            },

        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          _log(
            "User Joined",
            "User $remoteUid joined",
            level: LogLevel.success,
          );
          if (mounted) {
            setState(() {
              _remoteUid = remoteUid;
              _viewerCount++;
            });
            _addComment(
              username: 'User $remoteUid',
              message: 'joined the stream 🎉',
              isSystem: true,
            );
          }
        },

        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              _log(
                "User Offline",
                "User $remoteUid left",
                level: LogLevel.warning,
              );
              if (mounted) {
                setState(() {
                  if (_remoteUid == remoteUid) _remoteUid = null;
                  if (_viewerCount > 1) _viewerCount--;
                });
              }
            },

        onStreamMessage:
            (
              RtcConnection connection,
              int remoteUid,
              int streamId,
              Uint8List data,
              int length,
              int sentTs,
            ) {
              _handleIncomingStreamMessage(data, remoteUid);
            },

        onError: (ErrorCodeType err, String msg) {
          _log("Agora Error", "${err.name}: $msg", level: LogLevel.error);
          if (mounted) {
            setState(
              () => _agoraErrorMessage = "Agora error (${err.name}): $msg",
            );
          }
        },
      ),
    );

    // 4. Enable Video
    await _engine!.enableVideo();

    // 5. Set Client Role
    final role = widget.isHost
        ? ClientRoleType.clientRoleBroadcaster
        : ClientRoleType.clientRoleAudience;
    await _engine!.setClientRole(role: role);

    // 6. Camera Preview if Host
    if (widget.isHost) {
      await _engine!.startPreview();
    }

    // 7. Join Channel
    try {
      await _engine!.joinChannel(
        token: token,
        channelId: widget.channelName,
        uid: 0,
        options: ChannelMediaOptions(
          clientRoleType: role,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          publishCameraTrack: widget.isHost,
          publishMicrophoneTrack: widget.isHost,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      if (mounted) {
        setState(() => _isEngineReady = true);
      }
    } catch (e) {
      _log("Channel Join", "Join channel failed: $e", level: LogLevel.error);
    }

    _initAgoraChat();
  }

  // Initialize Agora Chat SDK
  Future<void> _initAgoraChat() async {
    if (chatAppKey.isEmpty || chatAppKey == "YOUR_CHAT_APP_KEY") return;

    try {
      final options = ChatOptions.withAppKey(chatAppKey, autoLogin: false);
      await ChatClient.getInstance.init(options);
      await ChatClient.getInstance.loginWithToken(userId, chatToken);
      _log("Chat SDK", "Logged in as $userId", level: LogLevel.success);
      if (mounted) {
        setState(() => _chatLoggedIn = true);
      }
    } catch (e) {
      _log("Chat SDK", "Login failed: $e", level: LogLevel.warning);
    }
  }

  void _handleIncomingStreamMessage(Uint8List data, int remoteUid) {
    try {
      final jsonStr = utf8.decode(data);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final type = map['type'] as String?;

      if (type == 'comment') {
        final username = map['username'] as String? ?? 'User $remoteUid';
        final text = map['message'] as String? ?? '';
        final isHost = map['isHost'] as bool? ?? false;
        _addComment(username: username, message: text, isHost: isHost);
      } else if (type == 'reaction') {
        final iconType = map['iconType'] as String? ?? 'heart';
        final colorVal = map['color'] as int? ?? 0xFFFF1744;
        final icon = iconType == 'fire'
            ? Icons.local_fire_department
            : Icons.favorite;
        _spawnFloatingReaction(
          icon: icon,
          iconType: iconType,
          color: Color(colorVal),
          broadcast: false,
        );
      }
    } catch (e) {
      _log("Stream Message", "Failed to parse: $e", level: LogLevel.error);
    }
  }

  void _addComment({
    required String username,
    required String message,
    bool isHost = false,
    bool isSystem = false,
  }) {
    if (!mounted) return;
    setState(() {
      _comments.add(
        LiveCommentModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          username: username,
          message: message,
          avatarColor: isSystem
              ? Colors.grey
              : _avatarColors[_random.nextInt(_avatarColors.length)],
          isHost: isHost,
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();

    _addComment(
      username: widget.username,
      message: text,
      isHost: widget.isHost,
    );

    if (_engine == null || _dataStreamId == null) {
      _log(
        "Comment Send",
        "Broadcast skipped: DataStream unavailable for audience",
        level: LogLevel.warning,
      );
      return;
    }

    try {
      final payload = jsonEncode({
        'type': 'comment',
        'username': widget.username,
        'message': text,
        'isHost': widget.isHost,
      });
      final bytes = Uint8List.fromList(utf8.encode(payload));
      await _engine!.sendStreamMessage(
        streamId: _dataStreamId!,
        data: bytes,
        length: bytes.length,
      );
      _log("Comment Send", "Comment sent via stream", level: LogLevel.success);
    } catch (e) {
      _log("Comment Send", "Send failed: $e", level: LogLevel.error);
    }
  }

  void _spawnFloatingReaction({
    IconData icon = Icons.favorite,
    String iconType = 'heart',
    Color? color,
    bool broadcast = true,
  }) {
    final reactionColor =
        color ?? _heartColors[_random.nextInt(_heartColors.length)];
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    setState(() {
      _reactions.add(
        FloatingReaction(
          id: id,
          startX: 0.65 + _random.nextDouble() * 0.25,
          color: reactionColor,
          icon: icon,
        ),
      );
    });

    if (broadcast && _engine != null && _dataStreamId != null) {
      try {
        final payload = jsonEncode({
          'type': 'reaction',
          'iconType': iconType,
          'color': reactionColor.toARGB32(),
        });
        final bytes = Uint8List.fromList(utf8.encode(payload));
        _engine!.sendStreamMessage(
          streamId: _dataStreamId!,
          data: bytes,
          length: bytes.length,
        );
      } catch (e) {
        _log("Reaction", "Broadcast error: $e", level: LogLevel.warning);
      }
    }
  }

  void _removeReaction(String id) {
    if (mounted) {
      setState(() => _reactions.removeWhere((r) => r.id == id));
    }
  }

  void _onToggleMute() {
    if (_engine == null) return;
    setState(() => _isMuted = !_isMuted);
    _engine!.muteLocalAudioStream(_isMuted);
  }

  void _onSwitchCamera() {
    if (_engine == null) return;
    _engine!.switchCamera();
  }

  void _openDiagnosticsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DiagnosticsSheet(
        logs: _logs,
        channelName: widget.channelName,
        isHost: widget.isHost,
        username: widget.username,
        appId: appId,
        token: token,
        connectionStateStr: _connectionStateStr,
        dataStreamId: _dataStreamId,
        chatLoggedIn: _chatLoggedIn,
        onClearLogs: () {
          setState(() => _logs.clear());
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          widget.isHost ? 'End Live Stream?' : 'Leave Live Stream?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          widget.isHost
              ? 'Are you sure you want to end this live broadcast?'
              : 'Are you sure you want to leave this stream?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(widget.isHost ? 'End Stream' : 'Leave'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // 1. Full Screen Video Layer
            Positioned.fill(
              child: widget.isHost
                  ? (_localUserJoined
                        ? _localVideoWidget()
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Starting live broadcast...',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'State: $_connectionStateStr',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ))
                  : _remoteVideoWidget(),
            ),

            // 2. Subtle Dark Gradient Overlay at Bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 380,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Instagram Live Top Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: LiveTopBarWidget(
                channelName: widget.channelName,
                isHost: widget.isHost,
                viewerCount: _viewerCount,
                logCount: _logs.length,
                onTapLogs: _openDiagnosticsModal,
                onClose: () => _confirmExit(context),
              ),
            ),

            // 4. Floating Hearts Layer
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: _reactions.map((reaction) {
                    return AnimatedHeartWidget(
                      key: ValueKey(reaction.id),
                      reaction: reaction,
                      onComplete: () => _removeReaction(reaction.id),
                    );
                  }).toList(),
                ),
              ),
            ),

            // 5. Live Comments List
            Positioned(
              left: 16,
              right: 80,
              bottom: bottomInset + 75,
              height: 220,
              child: LiveCommentsListWidget(
                comments: _comments,
                scrollController: _scrollController,
              ),
            ),

            // 6. Instagram Bottom Action Bar
            Positioned(
              left: 12,
              right: 12,
              bottom: bottomInset + 12,
              child: LiveBottomBarWidget(
                commentController: _commentController,
                hasInputText: _hasInputText,
                onSendComment: _sendComment,
                onFireReaction: () => _spawnFloatingReaction(
                  icon: Icons.local_fire_department,
                  iconType: 'fire',
                  color: const Color(0xFFFF6D00),
                ),
                onHeartReaction: () => _spawnFloatingReaction(
                  icon: Icons.favorite,
                  iconType: 'heart',
                ),
              ),
            ),

            // 7. Host Floating Controls
            if (widget.isHost)
              Positioned(
                top: MediaQuery.of(context).padding.top + 70,
                right: 16,
                child: HostControlsWidget(
                  isMuted: _isMuted,
                  onToggleMute: _onToggleMute,
                  onSwitchCamera: _onSwitchCamera,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _localVideoWidget() {
    if (!_isEngineReady || _engine == null) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(
          uid: 0,
          renderMode: RenderModeType.renderModeHidden,
        ),
      ),
    );
  }

  Widget _remoteVideoWidget() {
    if (_remoteUid != null && _engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(
            uid: _remoteUid,
            renderMode: RenderModeType.renderModeHidden,
          ),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                _agoraErrorMessage != null
                    ? _agoraErrorMessage!
                    : (_localUserJoined
                          ? 'Joined channel "${widget.channelName}"\nWaiting for host video stream...'
                          : 'Connecting to channel "${widget.channelName}"...\nState: $_connectionStateStr'),
                style: TextStyle(
                  color: _agoraErrorMessage != null
                      ? Colors.redAccent
                      : Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _openDiagnosticsModal,
                icon: const Icon(Icons.bug_report, size: 16),
                label: const Text('View Diagnostic Logs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
