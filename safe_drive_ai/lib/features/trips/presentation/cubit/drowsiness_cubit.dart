import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../services/drowsiness_detection_service.dart';

enum DrowsinessLevel { level1, level2 }

class DrowsinessAlert extends Equatable {
  const DrowsinessAlert({
    required this.level,
    required this.reason,
    required this.triggeredAt,
  });
  final DrowsinessLevel level;
  final String reason;
  final DateTime triggeredAt;

  @override
  List<Object?> get props => [level, reason, triggeredAt];
}

class DrowsinessState extends Equatable {
  const DrowsinessState({
    required this.isDrowsy,
    required this.faceDetected,
    required this.faceMissing,
    required this.detectionPaused,
    required this.eyesClosed,
    required this.yawning,
    required this.headDown,
    required this.eyesClosedDuration,
    required this.headDownDuration,
    required this.alertSequence,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.averageEyeOpenProbability,
    this.headPitch,
    this.lastAlert,
    this.reason,
  });

  const DrowsinessState.initial()
      : isDrowsy = false,
        faceDetected = false,
        faceMissing = false,
        detectionPaused = false,
        eyesClosed = false,
        yawning = false,
        headDown = false,
        eyesClosedDuration = Duration.zero,
        headDownDuration = Duration.zero,
        alertSequence = 0,
        leftEyeOpenProbability = null,
        rightEyeOpenProbability = null,
        averageEyeOpenProbability = null,
        headPitch = null,
        lastAlert = null,
        reason = null;

  final bool isDrowsy;
  final bool faceDetected;
  final bool faceMissing;
  final bool detectionPaused;
  final bool eyesClosed;
  final bool yawning;
  final bool headDown;
  final Duration eyesClosedDuration;
  final Duration headDownDuration;
  final int alertSequence;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final double? averageEyeOpenProbability;
  final double? headPitch;
  final DrowsinessAlert? lastAlert;
  final String? reason;

  DrowsinessState copyWith({
    bool? isDrowsy,
    bool? faceDetected,
    bool? faceMissing,
    bool? detectionPaused,
    bool? eyesClosed,
    bool? yawning,
    bool? headDown,
    Duration? eyesClosedDuration,
    Duration? headDownDuration,
    int? alertSequence,
    double? leftEyeOpenProbability,
    double? rightEyeOpenProbability,
    double? averageEyeOpenProbability,
    double? headPitch,
    DrowsinessAlert? lastAlert,
    String? reason,
  }) {
    return DrowsinessState(
      isDrowsy: isDrowsy ?? this.isDrowsy,
      faceDetected: faceDetected ?? this.faceDetected,
      faceMissing: faceMissing ?? this.faceMissing,
      detectionPaused: detectionPaused ?? this.detectionPaused,
      eyesClosed: eyesClosed ?? this.eyesClosed,
      yawning: yawning ?? this.yawning,
      headDown: headDown ?? this.headDown,
      eyesClosedDuration: eyesClosedDuration ?? this.eyesClosedDuration,
      headDownDuration: headDownDuration ?? this.headDownDuration,
      alertSequence: alertSequence ?? this.alertSequence,
      leftEyeOpenProbability:
          leftEyeOpenProbability ?? this.leftEyeOpenProbability,
      rightEyeOpenProbability:
          rightEyeOpenProbability ?? this.rightEyeOpenProbability,
      averageEyeOpenProbability:
          averageEyeOpenProbability ?? this.averageEyeOpenProbability,
      headPitch: headPitch ?? this.headPitch,
      lastAlert: lastAlert,
      reason: reason,
    );
  }

  @override
  List<Object?> get props => [
        isDrowsy,
        faceDetected,
        faceMissing,
        detectionPaused,
        eyesClosed,
        yawning,
        headDown,
        eyesClosedDuration,
        headDownDuration,
        alertSequence,
        leftEyeOpenProbability,
        rightEyeOpenProbability,
        averageEyeOpenProbability,
        headPitch,
        lastAlert,
        reason,
      ];
}

/// Cubit de somnolencia basado en duracion continua de señales.
///
/// - Ojos cerrados: alerta nivel 1 cuando supera 1s continuos.
/// - Cabeceo hacia adelante: alerta nivel 2 cuando supera 1s continuos.
/// - Si no hay rostro por >10s, se pausa la deteccion.
class DrowsinessCubit extends Cubit<DrowsinessState> {
  DrowsinessCubit({
    DrowsinessDetectionService? service,
    this.eyesClosedThreshold = const Duration(seconds: 1),
    this.headDownThreshold = const Duration(seconds: 1),
    this.faceMissingThreshold = const Duration(seconds: 10),
  })  : _service = service ?? DrowsinessDetectionService(),
        super(const DrowsinessState.initial());

  final DrowsinessDetectionService _service;
  final Duration eyesClosedThreshold;
  final Duration headDownThreshold;
  final Duration faceMissingThreshold;

  bool _isProcessing = false;
  DateTime? _eyesClosedSince;
  DateTime? _headDownSince;
  DateTime? _noFaceSince;
  bool _eyesAlertSent = false;
  bool _headAlertSent = false;
  int _alertSequence = 0;
  static const double _yawnBoostFactor = 0.85;
  bool _headDownActive = false;
  static const double _headDownStartThreshold = 10;
  static const double _headDownStopThreshold = 9;
  bool _eyesClosedActive = false;
  static const double _eyesClosedStartThreshold = 0.5;
  static const double _eyesClosedStopThreshold = 0.52;
  int _yawnFrames = 0;
  static const int _yawnFramesThreshold = 2;

  Future<void> processFrame(
    CameraImage image,
    InputImageRotation imageRotation,
  ) async {
    if (_isProcessing || isClosed) return;
    _isProcessing = true;

    try {
      final now = DateTime.now();
      final result = await _service.processImage(image, imageRotation);
      if (isClosed) return;

      if (!result.faceDetected) {
        _handleNoFace(now);
        return;
      }

      _handleFaceDetected(now, result);
    } finally {
      _isProcessing = false;
    }
  }

  void _handleNoFace(DateTime now) {
    _noFaceSince ??= now;
    final missingDuration = now.difference(_noFaceSince!);
    final faceMissing = missingDuration >= faceMissingThreshold;

    if (faceMissing) {
      _resetAlertTracking();
    }

    emit(
      state.copyWith(
        isDrowsy: false,
        faceDetected: false,
        faceMissing: faceMissing,
        detectionPaused: faceMissing,
        eyesClosed: false,
        yawning: false,
        headDown: false,
        eyesClosedDuration: Duration.zero,
        headDownDuration: Duration.zero,
        leftEyeOpenProbability: null,
        rightEyeOpenProbability: null,
        averageEyeOpenProbability: null,
        headPitch: null,
        lastAlert: null,
        reason: null,
      ),
    );
  }

  void _handleFaceDetected(DateTime now, DrowsinessFrameResult result) {
    if (_noFaceSince != null || state.faceMissing) {
      _resetAlertTracking();
      _noFaceSince = null;
    }

    final eyesClosed = _resolveEyesClosed(result);
    final yawning = _resolveYawning(result.yawning);
    final headDown = _resolveHeadDown(result.headPitch);

    final eyesClosedDuration = _updateDuration(
      now: now,
      isActive: eyesClosed,
      startTime: _eyesClosedSince,
      onStart: () => _eyesClosedSince = now,
      onReset: () {
        _eyesClosedSince = null;
        _eyesAlertSent = false;
      },
    );

    final headDownDuration = _updateDuration(
      now: now,
      isActive: headDown,
      startTime: _headDownSince,
      onStart: () => _headDownSince = now,
      onReset: () {
        _headDownSince = null;
        _headAlertSent = false;
      },
    );

    final adjustedEyesThreshold = yawning
      ? _scaledDuration(eyesClosedThreshold, _yawnBoostFactor)
      : eyesClosedThreshold;
    final alert = _resolveAlert(
      now,
      eyesClosedDuration,
      headDownDuration,
      adjustedEyesThreshold,
    );
    final isDrowsy = eyesClosedDuration >= adjustedEyesThreshold ||
      headDownDuration >= headDownThreshold;

    emit(
      state.copyWith(
        isDrowsy: isDrowsy,
        faceDetected: true,
        faceMissing: false,
        detectionPaused: false,
        eyesClosed: eyesClosed,
        yawning: yawning,
        headDown: headDown,
        eyesClosedDuration: eyesClosedDuration,
        headDownDuration: headDownDuration,
        alertSequence: _alertSequence,
        leftEyeOpenProbability: result.leftEyeOpenProbability,
        rightEyeOpenProbability: result.rightEyeOpenProbability,
        averageEyeOpenProbability: result.averageEyeOpenProbability,
        headPitch: result.headPitch,
        lastAlert: alert,
        reason: _buildReason(isDrowsy, eyesClosed, headDown),
      ),
    );
  }

  Duration _updateDuration({
    required DateTime now,
    required bool isActive,
    required DateTime? startTime,
    required void Function() onStart,
    required void Function() onReset,
  }) {
    if (!isActive) {
      onReset();
      return Duration.zero;
    }

    if (startTime == null) {
      onStart();
      return Duration.zero;
    }

    return now.difference(startTime);
  }

  DrowsinessAlert? _resolveAlert(
    DateTime now,
    Duration eyesClosedDuration,
    Duration headDownDuration,
    Duration adjustedEyesThreshold,
  ) {
    if (headDownDuration >= headDownThreshold && !_headAlertSent) {
      _headAlertSent = true;
      _alertSequence++;
      return DrowsinessAlert(
        level: DrowsinessLevel.level2,
        reason: 'Cabeceo detectado',
        triggeredAt: now,
      );
    }

    if (eyesClosedDuration >= adjustedEyesThreshold && !_eyesAlertSent) {
      _eyesAlertSent = true;
      _alertSequence++;
      return DrowsinessAlert(
        level: DrowsinessLevel.level1,
        reason: 'Ojos cerrados prolongados',
        triggeredAt: now,
      );
    }

    return null;
  }

  String? _buildReason(bool isDrowsy, bool eyesClosed, bool headDown) {
    if (!isDrowsy) return null;
    if (headDown) return 'Cabeceo detectado';
    if (eyesClosed) return 'Ojos cerrados prolongados';
    return 'Somnolencia detectada';
  }

  Duration _scaledDuration(Duration base, double factor) {
    return Duration(
      milliseconds: (base.inMilliseconds * factor).round(),
    );
  }

  void _resetAlertTracking() {
    _eyesClosedSince = null;
    _headDownSince = null;
    _eyesAlertSent = false;
    _headAlertSent = false;
    _headDownActive = false;
    _eyesClosedActive = false;
    _yawnFrames = 0;
  }

  bool _resolveEyesClosed(DrowsinessFrameResult result) {
    final left = result.leftEyeOpenProbability;
    final right = result.rightEyeOpenProbability;
    final avg = result.averageEyeOpenProbability;

    if (left == null && right == null && avg == null) {
      _eyesClosedActive = false;
      return false;
    }

    final belowStart = left != null && right != null
      ? left < _eyesClosedStartThreshold &&
        right < _eyesClosedStartThreshold
      : avg != null && avg < _eyesClosedStartThreshold;

    final aboveStop = (left != null && left >= _eyesClosedStopThreshold) ||
      (right != null && right >= _eyesClosedStopThreshold) ||
      (avg != null && avg >= _eyesClosedStopThreshold);

    if (_eyesClosedActive) {
      if (aboveStop) {
        _eyesClosedActive = false;
      }
    } else if (belowStart) {
      _eyesClosedActive = true;
    }

    return _eyesClosedActive;
  }

  bool _resolveYawning(bool rawYawning) {
    if (rawYawning) {
      _yawnFrames = (_yawnFrames + 1).clamp(0, 4);
    } else {
      _yawnFrames = (_yawnFrames - 1).clamp(0, 4);
    }

    return _yawnFrames >= _yawnFramesThreshold;
  }

  bool _resolveHeadDown(double? headPitch) {
    if (headPitch == null) {
      _headDownActive = false;
      return false;
    }

    final absPitch = headPitch.abs();
    if (_headDownActive) {
      if (absPitch < _headDownStopThreshold) {
        _headDownActive = false;
      }
    } else if (absPitch >= _headDownStartThreshold) {
      _headDownActive = true;
    }

    return _headDownActive;
  }

  void reset() {
    _resetAlertTracking();
    _noFaceSince = null;
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
