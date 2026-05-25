import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/driver_clips_bloc.dart';
import '../bloc/driver_clips_event.dart';
import '../bloc/driver_clips_state.dart';
import '../widgets/clip_tile_widget.dart';
import '../widgets/video_clip_player_modal.dart';

class DriverClipsPage extends StatefulWidget {
  final String driverId;
  final String driverName;

  const DriverClipsPage({
    required this.driverId,
    required this.driverName,
    super.key,
  });

  @override
  State<DriverClipsPage> createState() => _DriverClipsPageState();
}

class _DriverClipsPageState extends State<DriverClipsPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    context.read<DriverClipsBloc>().add(
          DriverClipsPageOpened(driverId: widget.driverId),
        );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context
          .read<DriverClipsBloc>()
          .add(const DriverClipsLoadMoreRequested());
    }
  }

  // ── Dev only: inyecta clips ficticios sin tocar Firebase Storage ─────────
  void _seedMockClips() {
    context
        .read<DriverClipsBloc>()
        .add(const DriverClipsSeedMockRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverClipsBloc, DriverClipsState>(
      listenWhen: (prev, curr) {
        if (curr is DriverClipsVideoUrlReady) return true;
        if (curr is DriverClipsLoaded && curr.urlError != null) {
          if (prev is DriverClipsLoaded) return prev.urlError != curr.urlError;
          return true;
        }
        return false;
      },
      listener: (context, state) {
        if (state is DriverClipsVideoUrlReady) {
          showDialog(
            context: context,
            builder: (_) => VideoClipPlayerModal(
              clip: state.clip,
              downloadUrl: state.downloadUrl,
            ),
          ).whenComplete(() {
            if (!mounted) return;
            context.read<DriverClipsBloc>().add(
                  const DriverClipsVideoPlayerDismissed(),
                );
          });
        } else if (state is DriverClipsLoaded && state.urlError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo cargar el video. Intenta de nuevo.'),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Clips de ${widget.driverName}'),
          centerTitle: true,
          // Botón de sembrar datos mock — solo visible en debug
          actions: [
            if (kDebugMode)
              IconButton(
                icon: const Icon(Icons.science_outlined),
                tooltip: 'Cargar clips de prueba (mock)',
                onPressed: _seedMockClips,
              ),
          ],
        ),
        body: BlocBuilder<DriverClipsBloc, DriverClipsState>(
          builder: (context, state) {
            if (state is DriverClipsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DriverClipsEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay clips disponibles\npara este conductor.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            if (state is DriverClipsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${state.message}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.red[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<DriverClipsBloc>()
                          .add(const DriverClipsRetryRequested()),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            if (state is DriverClipsLoaded) {
              return Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        state.clips.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.clips.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final clip = state.clips[index];
                      return ClipTileWidget(
                        clip: clip,
                        onTap: () => context
                            .read<DriverClipsBloc>()
                            .add(DriverClipTapped(clip: clip)),
                      );
                    },
                  ),
                  if (state.isLoadingUrl)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x55000000),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
