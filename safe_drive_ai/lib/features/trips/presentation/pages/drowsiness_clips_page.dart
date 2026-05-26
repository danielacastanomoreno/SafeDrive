import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/constants/app_colors.dart';

/// Pantalla simple para ver clips de somnolencia grabados.
class DrowsinessClipsPage extends StatefulWidget {
  const DrowsinessClipsPage({super.key});

  @override
  State<DrowsinessClipsPage> createState() => _DrowsinessClipsPageState();
}

class _DrowsinessClipsPageState extends State<DrowsinessClipsPage> {
  late Future<List<File>> _clipFiles;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _clipFiles = _loadClips();
  }

  Future<List<File>> _loadClips() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final clipsDir = Directory('${directory.path}/drowsiness_clips');

      if (!await clipsDir.exists()) return [];

      // Buscar en la raíz y en subcarpetas (organizadas por driverId)
      final List<File> files = [];
      for (final entity in clipsDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.mp4')) {
          files.add(entity);
        }
      }

      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files;
    } catch (e) {
      debugPrint('[CLIPS] Error cargando clips: $e');
      return [];
    }
  }

  Future<void> _deleteClip(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar clip'),
        content: const Text('¿Estás seguro de que quieres eliminar este clip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await file.delete();
        setState(() {
          _clipFiles = _loadClips();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clip eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteAllClips() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todos los clips'),
        content: const Text('¿Estás seguro? Esto eliminará todos los clips.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar todo', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        final directory = await getApplicationDocumentsDirectory();
        final clipsDir = Directory('${directory.path}/drowsiness_clips');
        
        if (await clipsDir.exists()) {
          final files = clipsDir.listSync();
          for (var file in files) {
            if (file is File) {
              await file.delete();
            }
          }
        }
        
        setState(() {
          _clipFiles = _loadClips();
          _isDeleting = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todos los clips eliminados')),
          );
        }
      } catch (e) {
        setState(() => _isDeleting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  String _extractClipInfo(String fileName) {
    // trip_<tripId>_nivel1_<timestamp>_chunk0.mp4
    final parts = fileName.replaceAll('.mp4', '').split('_');
    if (parts.length >= 3) {
      final tripId = parts[1];
      final nivel = parts[2];
      return 'Viaje: $tripId | $nivel';
    }
    return fileName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clips de Somnolencia'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Eliminar todos',
            onPressed: _isDeleting ? null : _deleteAllClips,
          ),
        ],
      ),
      body: FutureBuilder<List<File>>(
        future: _clipFiles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay clips grabados'),
            );
          }

          final clips = snapshot.data!;
          return ListView.builder(
            itemCount: clips.length,
            itemBuilder: (context, index) {
              final file = clips[index];
              final fileName = file.path.split('/').last;
              final fileSize = file.statSync().size;
              final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
              final info = _extractClipInfo(fileName);
              final modified = file.statSync().modified;
              final dateStr = '${modified.day}/${modified.month}/${modified.year} ${modified.hour.toString().padLeft(2, '0')}:${modified.minute.toString().padLeft(2, '0')}';

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.videocam, color: Colors.red),
                  title: Text(info),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('$fileSizeMB MB • $dateStr', style: const TextStyle(fontSize: 12)),
                      Text(fileName, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () {
                            _showVideoPlayer(context, file);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteClip(file);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showVideoPlayer(BuildContext context, File videoFile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: _VideoPlayerDialog(videoFile: videoFile),
      ),
    );
  }
}

/// Widget simple para reproducir video.
class _VideoPlayerDialog extends StatefulWidget {
  final File videoFile;

  const _VideoPlayerDialog({required this.videoFile});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile);
    _initializeVideoPlayer = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.videoFile.path.split('/').last,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        FutureBuilder<void>(
          future: _initializeVideoPlayer,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              );
            } else {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                label: Text(_controller.value.isPlaying ? 'Pausar' : 'Reproducir'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
