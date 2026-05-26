import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../domain/entities/video_clip_entity.dart';

class VideoClipPlayerModal extends StatefulWidget {
  final VideoClipEntity clip;
  final String downloadUrl;

  const VideoClipPlayerModal({
    required this.clip,
    required this.downloadUrl,
    super.key,
  });

  @override
  State<VideoClipPlayerModal> createState() => _VideoClipPlayerModalState();
}

class _VideoClipPlayerModalState extends State<VideoClipPlayerModal> {
  late VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Archivo local → VideoPlayerController.file()
    // URL remota   → VideoPlayerController.networkUrl()
    final isLocal = widget.downloadUrl.startsWith('/');
    _controller = isLocal
        ? VideoPlayerController.file(File(widget.downloadUrl))
        : VideoPlayerController.networkUrl(Uri.parse(widget.downloadUrl));
    _controller.initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((e) {
      if (mounted) setState(() => _hasError = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss')
        .format(widget.clip.uploadedAt.toLocal());
    final eventColor = _eventColor(widget.clip.eventType);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                Icon(_eventIcon(widget.clip.eventType),
                    color: eventColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.clip.eventType.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: eventColor,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Video
          if (_controller.value.isInitialized)
            SizedBox(
              width: double.maxFinite,
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: _controller,
                      builder: (_, value, __) {
                        return GestureDetector(
                          onTap: () {
                            value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          },
                          child: AnimatedOpacity(
                            opacity: value.isPlaying ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(12),
                              child: const Icon(Icons.play_arrow,
                                  color: Colors.white, size: 36),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          else if (_hasError)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'No se pudo cargar el video.',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),

          // Botón pantalla completa
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.fullscreen),
              label: const Text('Pantalla completa'),
              onPressed: () {
                _controller.pause();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _FullScreenVideoPlayer(
                      controller: _controller,
                      clip: widget.clip,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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

class _FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final VideoClipEntity clip;

  const _FullScreenVideoPlayer({
    required this.controller,
    required this.clip,
  });

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  @override
  void initState() {
    super.initState();
    widget.controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.clip.eventType.displayName,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: widget.controller.value.aspectRatio,
          child: VideoPlayer(widget.controller),
        ),
      ),
    );
  }
}
