import 'package:flutter/material.dart';

/// Floating controls available only to the Host (microphone mute and camera flip)
class HostControlsWidget extends StatelessWidget {
  final bool isMuted;
  final VoidCallback onToggleMute;
  final VoidCallback onSwitchCamera;

  const HostControlsWidget({
    super.key,
    required this.isMuted,
    required this.onToggleMute,
    required this.onSwitchCamera,
  });

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCircleButton(
          icon: isMuted ? Icons.mic_off : Icons.mic,
          color: isMuted ? Colors.redAccent : Colors.white,
          onTap: onToggleMute,
        ),
        const SizedBox(height: 12),
        _buildCircleButton(
          icon: Icons.flip_camera_ios,
          color: Colors.white,
          onTap: onSwitchCamera,
        ),
      ],
    );
  }
}
