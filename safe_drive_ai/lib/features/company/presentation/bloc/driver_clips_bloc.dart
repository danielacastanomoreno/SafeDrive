import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/video_clip_entity.dart';
import '../../domain/usecases/fetch_driver_clips_usecase.dart';
import '../../domain/usecases/get_clip_download_url_usecase.dart';
import 'driver_clips_event.dart';
import 'driver_clips_state.dart';

class DriverClipsBloc extends Bloc<DriverClipsEvent, DriverClipsState> {
  final FetchDriverClipsUseCase fetchClipsUseCase;
  final GetClipDownloadUrlUseCase getDownloadUrlUseCase;

  static const int _pageSize = 20;
  String? _driverId;

  DriverClipsBloc({
    required this.fetchClipsUseCase,
    required this.getDownloadUrlUseCase,
  }) : super(const DriverClipsInitial()) {
    on<DriverClipsPageOpened>(_onPageOpened);
    on<DriverClipsLoadMoreRequested>(_onLoadMore);
    on<DriverClipsRetryRequested>(_onRetry);
    on<DriverClipTapped>(_onClipTapped);
    on<DriverClipsVideoPlayerDismissed>(_onVideoPlayerDismissed);
    if (kDebugMode) {
      on<DriverClipsSeedMockRequested>(_onSeedMock);
    }
  }

  Future<void> _onPageOpened(
    DriverClipsPageOpened event,
    Emitter<DriverClipsState> emit,
  ) async {
    _driverId = event.driverId;
    emit(const DriverClipsLoading());

    final result = await fetchClipsUseCase(
      FetchDriverClipsParams(
        driverId: event.driverId,
        pageSize: _pageSize,
        pageToken: null,
      ),
    );

    result.fold(
      (failure) => emit(DriverClipsError(message: failure.message)),
      (clips) {
        if (clips.isEmpty) {
          emit(const DriverClipsEmpty());
        } else {
          emit(DriverClipsLoaded(
            clips: clips,
            hasMore: clips.length == _pageSize,
            nextPageToken: _pageSize.toString(),
          ));
        }
      },
    );
  }

  Future<void> _onLoadMore(
    DriverClipsLoadMoreRequested event,
    Emitter<DriverClipsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DriverClipsLoaded) return;
    if (!currentState.hasMore || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await fetchClipsUseCase(
      FetchDriverClipsParams(
        driverId: _driverId!,
        pageSize: _pageSize,
        pageToken: currentState.nextPageToken,
      ),
    );

    result.fold(
      (_) => emit(currentState.copyWith(isLoadingMore: false)),
      (newClips) {
        final allClips = [...currentState.clips, ...newClips];
        final nextOffset =
            (int.tryParse(currentState.nextPageToken ?? '0') ?? 0) +
                newClips.length;
        emit(DriverClipsLoaded(
          clips: allClips,
          hasMore: newClips.length == _pageSize,
          nextPageToken: nextOffset.toString(),
        ));
      },
    );
  }

  Future<void> _onClipTapped(
    DriverClipTapped event,
    Emitter<DriverClipsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DriverClipsLoaded) return;

    emit(currentState.copyWith(isLoadingUrl: true));

    final result = await getDownloadUrlUseCase(
      GetClipDownloadUrlParams(
        firebaseStoragePath: event.clip.firebaseStoragePath,
      ),
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(
          isLoadingUrl: false,
          urlError: failure.message,
        ));
      },
      (downloadUrl) {
        emit(DriverClipsVideoUrlReady(
          clip: event.clip,
          downloadUrl: downloadUrl,
          clips: currentState.clips,
          hasMore: currentState.hasMore,
          nextPageToken: currentState.nextPageToken,
        ));
      },
    );
  }

  Future<void> _onRetry(
    DriverClipsRetryRequested event,
    Emitter<DriverClipsState> emit,
  ) async {
    if (_driverId != null) {
      add(DriverClipsPageOpened(driverId: _driverId!));
    }
  }

  /// Restaura el estado de lista cuando el reproductor se cierra,
  /// sin volver a buscar en Firebase Storage.
  Future<void> _onVideoPlayerDismissed(
    DriverClipsVideoPlayerDismissed event,
    Emitter<DriverClipsState> emit,
  ) async {
    final currentState = state;
    if (currentState is DriverClipsVideoUrlReady) {
      emit(DriverClipsLoaded(
        clips: currentState.clips,
        hasMore: currentState.hasMore,
        nextPageToken: currentState.nextPageToken,
      ));
    } else if (_driverId != null) {
      // Fallback solo si el estado ya no tiene clips (caso poco probable)
      add(DriverClipsPageOpened(driverId: _driverId!));
    }
  }

  // ── Debug only ────────────────────────────────────────────────────────────
  /// Inyecta clips ficticios en el estado sin tocar Firebase Storage.
  /// Usa URLs públicas de Google para que el reproductor funcione.
  Future<void> _onSeedMock(
    DriverClipsSeedMockRequested event,
    Emitter<DriverClipsState> emit,
  ) async {
    final now = DateTime.now();

    // Google public sample videos — small, always available
    const sampleUrls = [
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
    ];

    final mockClips = [
      VideoClipEntity(
        id: 'mock_nivel2_001',
        uploadedAt: now.subtract(const Duration(minutes: 10)),
        firebaseStoragePath: sampleUrls[0],
        eventType: ClipEventType.drowsinessLevel2,
      ),
      VideoClipEntity(
        id: 'mock_nivel1_002',
        uploadedAt: now.subtract(const Duration(hours: 1)),
        firebaseStoragePath: sampleUrls[1],
        eventType: ClipEventType.drowsinessLevel1,
      ),
      VideoClipEntity(
        id: 'mock_nivel1_003',
        uploadedAt: now.subtract(const Duration(hours: 2)),
        firebaseStoragePath: sampleUrls[2],
        eventType: ClipEventType.drowsinessLevel1,
      ),
      VideoClipEntity(
        id: 'mock_nivel2_004',
        uploadedAt: now.subtract(const Duration(hours: 3)),
        firebaseStoragePath: sampleUrls[3],
        eventType: ClipEventType.drowsinessLevel2,
      ),
      VideoClipEntity(
        id: 'mock_seatbelt_005',
        uploadedAt: now.subtract(const Duration(hours: 4)),
        firebaseStoragePath: sampleUrls[4],
        eventType: ClipEventType.seatbeltNotDetected,
      ),
    ];

    emit(DriverClipsLoaded(
      clips: mockClips,
      hasMore: false,
      nextPageToken: null,
    ));
  }
}
