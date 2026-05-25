import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/video_clip_entity.dart';

class ClipTileWidget extends StatelessWidget {
  final VideoClipEntity clip;
  final VoidCallback onTap;

  const ClipTileWidget({
    required this.clip,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('dd/MM/yyyy HH:mm:ss').format(clip.uploadedAt.toLocal());

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _eventColor(clip.eventType).withValues(alpha: 0.12),
        child: Icon(
          _eventIcon(clip.eventType),
          color: _eventColor(clip.eventType),
          size: 22,
        ),
      ),
      title: Text(
        clip.eventType.displayName,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: _eventColor(clip.eventType),
        ),
      ),
      subtitle: Text(formattedDate),
      trailing: const Icon(Icons.play_circle_outline, size: 28),
      onTap: onTap,
    );
  }

  static Color _eventColor(ClipEventType type) {
    switch (type) {
      case ClipEventType.drowsinessLevel1:
        return Colors.orange;
      case ClipEventType.drowsinessLevel2:
        return Colors.red;
      case ClipEventType.seatbeltNotDetected:
        return Colors.deepPurple;
      case ClipEventType.unknown:
        return Colors.grey;
    }
  }

  static IconData _eventIcon(ClipEventType type) {
    switch (type) {
      case ClipEventType.drowsinessLevel1:
        return Icons.bedtime_outlined;
      case ClipEventType.drowsinessLevel2:
        return Icons.warning_amber_rounded;
      case ClipEventType.seatbeltNotDetected:
        return Icons.no_crash_outlined;
      case ClipEventType.unknown:
        return Icons.videocam_outlined;
    }
  }
}
