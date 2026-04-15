import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../services/seatbelt_detection_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Estados
// ─────────────────────────────────────────────────────────────────────────────

abstract class SeatbeltState extends Equatable {
  const SeatbeltState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de que el servicio procese cualquier frame.
class SeatbeltInitial extends SeatbeltState {
  const SeatbeltInitial();
}

/// El cinturón fue detectado con suficiente confianza.
class SeatbeltDetected extends SeatbeltState {
  const SeatbeltDetected();
}

/// El cinturón NO está puesto (N frames consecutivos sin detección).
class SeatbeltNotDetected extends SeatbeltState {
  const SeatbeltNotDetected();
}

/// No hay suficiente información (poca luz, conductor fuera de cuadro, etc.).
class SeatbeltUnknown extends SeatbeltState {
  const SeatbeltUnknown();
}

// ─────────────────────────────────────────────────────────────────────────────
// Cubit
// ─────────────────────────────────────────────────────────────────────────────

/// Cubit que gestiona la detección continua del cinturón de seguridad.
///
/// Internamente usa [SeatbeltDetectionService] para analizar frames de cámara.
/// Solo emite [SeatbeltNotDetected] cuando hay [framesThreshold] frames
/// consecutivos sin detección, para evitar falsos positivos por oclusión
/// momentánea.
class SeatbeltCubit extends Cubit<SeatbeltState> {
  SeatbeltCubit({
    SeatbeltDetectionService? service,
    this.framesThreshold = 10,
  })  : _service = service ?? SeatbeltDetectionService(),
        super(const SeatbeltInitial());

  final SeatbeltDetectionService _service;

  /// Número de frames consecutivos sin cinturón antes de emitir alerta.
  final int framesThreshold;

  int _noSeatbeltFrames = 0;
  bool _isProcessing = false;

  /// Procesa un frame de cámara.
  ///
  /// [imageRotation] debe ser la rotación del sensor de la cámara activa.
  /// Solo procesa un frame a la vez; si ya hay uno en proceso, lo descarta.
  Future<void> processFrame(
    CameraImage image,
    InputImageRotation imageRotation,
  ) async {
    if (_isProcessing || isClosed) return;
    _isProcessing = true;

    try {
      final status = await _service.processImage(image, imageRotation);
      if (isClosed) return;

      switch (status) {
        case SeatbeltStatus.detected:
          _noSeatbeltFrames = 0;
          if (state is! SeatbeltDetected) {
            emit(const SeatbeltDetected());
          }

        case SeatbeltStatus.notDetected:
          _noSeatbeltFrames++;
          if (_noSeatbeltFrames >= framesThreshold &&
              state is! SeatbeltNotDetected) {
            emit(const SeatbeltNotDetected());
          }

        case SeatbeltStatus.unknown:
          // No modificar el estado previo cuando la confianza es baja.
          // Si estábamos en notDetected, mantenemos la alerta activa.
          if (state is SeatbeltInitial) {
            emit(const SeatbeltUnknown());
          }
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Reinicia el contador de frames sin cinturón y vuelve al estado inicial.
  /// Llamar cuando el viaje termina o la cámara no está disponible.
  void reset() {
    _noSeatbeltFrames = 0;
    if (!isClosed) emit(const SeatbeltInitial());
  }

  @override
  Future<void> close() async {
    await _service.close();
    return super.close();
  }
}
