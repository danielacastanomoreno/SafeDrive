import 'package:equatable/equatable.dart';

import '../../domain/entities/video_clip_entity.dart';

abstract class DriverClipsState extends Equatable {
  const DriverClipsState();

  @override
  List<Object?> get props => [];
}

class DriverClipsInitial extends DriverClipsState {
  const DriverClipsInitial();
}

class DriverClipsLoading extends DriverClipsState {
  const DriverClipsLoading();
}

class DriverClipsLoaded extends DriverClipsState {
  final List<VideoClipEntity> clips;
  final bool hasMore;
  final String? nextPageToken;
  final bool isLoadingMore;
  final bool isLoadingUrl;
  // Cuando no es null el BlocListener muestra un snackbar y la lista no se reemplaza.
  final String? urlError;

  const DriverClipsLoaded({
    required this.clips,
    required this.hasMore,
    this.nextPageToken,
    this.isLoadingMore = false,
    this.isLoadingUrl = false,
    this.urlError,
  });

  DriverClipsLoaded copyWith({
    List<VideoClipEntity>? clips,
    bool? hasMore,
    String? nextPageToken,
    bool? isLoadingMore,
    bool? isLoadingUrl,
    String? urlError,
  }) {
    return DriverClipsLoaded(
      clips: clips ?? this.clips,
      hasMore: hasMore ?? this.hasMore,
      nextPageToken: nextPageToken ?? this.nextPageToken,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isLoadingUrl: isLoadingUrl ?? this.isLoadingUrl,
      urlError: urlError,
    );
  }

  @override
  List<Object?> get props =>
      [clips, hasMore, nextPageToken, isLoadingMore, isLoadingUrl, urlError];
}

class DriverClipsEmpty extends DriverClipsState {
  const DriverClipsEmpty();
}

class DriverClipsError extends DriverClipsState {
  final String message;

  const DriverClipsError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Estado de un solo uso — el BLoC lo emite cuando la URL está lista
// para que la página abra el modal, luego regresa a DriverClipsLoaded.
class DriverClipsVideoUrlReady extends DriverClipsState {
  final VideoClipEntity clip;
  final String downloadUrl;
  final List<VideoClipEntity> clips;
  final bool hasMore;
  final String? nextPageToken;

  const DriverClipsVideoUrlReady({
    required this.clip,
    required this.downloadUrl,
    required this.clips,
    required this.hasMore,
    this.nextPageToken,
  });

  @override
  List<Object?> get props =>
      [clip, downloadUrl, clips, hasMore, nextPageToken];
}
