import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../services/drowsiness_detection_service.dart';

class DrowsinessState extends Equatable {
  const DrowsinessState({
    required this.score,
    required this.isDrowsy,
    required this.faceDetected,
    required this.eyesClosed,
    required this.yawning,
    this.averageEyeOpenProbability,
    this.mouthAspectRatio,
    this.reason,
  });

  const DrowsinessState.initial()
      : score = 0,
        isDrowsy = false,
        faceDetected = false,
        eyesClosed = false,
        yawning = false,
        averageEyeOpenProbability = null,
        mouthAspectRatio = null,
        reason = null;

  final int score;
  final bool isDrowsy;
  final bool faceDetected;
  final bool eyesClosed;
  final bool yawning;
  final double? averageEyeOpenProbability;
  final double? mouthAspectRatio;
  final String? reason;

  DrowsinessState copyWith({
    int? score,
    bool? isDrowsy,
    bool? faceDetected,
    bool? eyesClosed,
    bool? yawning,
    double? averageEyeOpenProbability,
    double? mouthAspectRatio,
    String? reason,
  }) {
    return DrowsinessState(
      score: score ?? this.score,
      isDrowsy: isDrowsy ?? this.isDrowsy,
      faceDetected: faceDetected ?? this.faceDetected,
      eyesClosed: eyesClosed ?? this.eyesClosed,
      yawning: yawning ?? this.yawning,
      averageEyeOpenProbability:
          averageEyeOpenProbability ?? this.averageEyeOpenProbability,
      mouthAspectRatio: mouthAspectRatio ?? this.mouthAspectRatio,
      reason: reason,
    );
  }

  @override
  List<Object?> get props => [
        score,
        isDrowsy,
        faceDetected,
        eyesClosed,
        yawning,
        averageEyeOpenProbability,
        mouthAspectRatio,
        reason,
      ];
}

/// Cubit de somnolencia inspirado en el enfoque de score incremental.
///
/// Si hay señales de somnolencia (ojos cerrados o bostezo), el score sube.
/// Si no, el score baja gradualmente.
class DrowsinessCubit extends Cubit<DrowsinessState> {
  DrowsinessCubit({
    DrowsinessDetectionService? service,
    this.alertThreshold = 5,
  })  : _service = service ?? DrowsinessDetectionService(),
        super(const DrowsinessState.initial());

  final DrowsinessDetectionService _service;
  final int alertThreshold;

  bool _isProcessing = false;
  int _score = 0;

  Future<void> processFrame(
    CameraImage image,
    InputImageRotation imageRotation,
  ) async {
    if (_isProcessing || isClosed) return;
    _isProcessing = true;

    try {
      final result = await _service.processImage(image, imageRotation);
      if (isClosed) return;

      if (!result.faceDetected) {
        _score = math.max(0, _score - 1);
        final isDrowsy = _score >= alertThreshold;
        emit(
          state.copyWith(
            score: _score,
            isDrowsy: isDrowsy,
            faceDetected: false,
            eyesClosed: false,
            yawning: false,
            averageEyeOpenProbability: null,
            mouthAspectRatio: null,
            reason: isDrowsy ? state.reason : null,
          ),
        );
        return;
      }

      final hasDrowsySignal = result.eyesClosed || result.yawning;
      if (hasDrowsySignal) {
        _score += 1;
      } else {
        _score = math.max(0, _score - 1);
      }

      final isDrowsy = _score >= alertThreshold;
      final reason = isDrowsy ? _buildReason(result) : null;

      emit(
        state.copyWith(
          score: _score,
          isDrowsy: isDrowsy,
          faceDetected: true,
          eyesClosed: result.eyesClosed,
          yawning: result.yawning,
          averageEyeOpenProbability: result.averageEyeOpenProbability,
          mouthAspectRatio: result.mouthAspectRatio,
          reason: reason,
        ),
      );
    } finally {
      _isProcessing = false;
    }
  }

  String _buildReason(DrowsinessFrameResult result) {
    if (result.eyesClosed && result.yawning) {
      return 'Ojos cerrados y bostezo detectados';
    }
    if (result.eyesClosed) {
      return 'Ojos cerrados detectados';
    }
    if (result.yawning) {
      return 'Bostezo detectado';
    }
    return 'Patron de fatiga detectado';
  }

  void reset() {
    _score = 0;
    if (!isClosed) {
      emit(const DrowsinessState.initial());
    }
  }

  @override
  Future<void> close() async {
    await _service.close();
    return super.close();
  }
}
