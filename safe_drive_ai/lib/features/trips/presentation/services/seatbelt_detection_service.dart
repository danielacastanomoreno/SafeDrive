import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Resultado de la detección de cinturón de seguridad.
enum SeatbeltStatus {
  /// Cinturón detectado con suficiente confianza.
  detected,

  /// Cinturón NO detectado con suficiente confianza.
  notDetected,

  /// No hay suficiente información (landmarks de baja confianza o sin pose).
  unknown,
}

/// Servicio que analiza frames de cámara con ML Kit Pose Detection para
/// inferir la presencia del cinturón de seguridad.
///
/// Lógica de inferencia:
/// La cámara frontal captura al conductor. Un cinturón correctamente puesto
/// cruza diagonalmente el torso: entra por el hombro izquierdo (desde la
/// perspectiva del conductor) y termina en la cadera contralateral.
/// Esto genera una asimetría horizontal medible:
///   - El hombro izquierdo (landmark `leftShoulder`) está desplazado hacia
///     la derecha respecto a la cadera izquierda (`leftHip`) porque la
///     banda tira el hombro hacia el centro del torso.
///   - Adicionalmente, el delta-X entre hombro derecho y cadera derecha
///     será pequeño (lado libre sin cinta).
///
/// Threshold configurable mediante [diagonalThreshold] (valor normalizado
/// en el rango [0, 1] del ancho de imagen).
class SeatbeltDetectionService {
  SeatbeltDetectionService({this.diagonalThreshold = 0.04})
      : _detector = PoseDetector(
          options: PoseDetectorOptions(
            mode: PoseDetectionMode.stream,
          ),
        );

  /// Umbral mínimo de diferencia normalizada en X entre hombro izquierdo
  /// y cadera izquierda para considerar que hay cinturón.
  final double diagonalThreshold;

  /// Confianza mínima exigida a cada landmark para considerarlo válido.
  static const double _minLikelihood = 0.5;

  final PoseDetector _detector;
  bool _isClosed = false;

  /// Procesa un [CameraImage] en formato YUV420 o BGRA8888 y devuelve
  /// el [SeatbeltStatus] inferido.
  ///
  /// [imageRotation] debe reflejar la orientación del sensor de la cámara.
  Future<SeatbeltStatus> processImage(
    CameraImage image,
    InputImageRotation imageRotation,
  ) async {
    if (_isClosed) return SeatbeltStatus.unknown;

    final inputImage = _buildInputImage(image, imageRotation);
    if (inputImage == null) return SeatbeltStatus.unknown;

    List<Pose> poses;
    try {
      poses = await _detector.processImage(inputImage);
    } catch (_) {
      return SeatbeltStatus.unknown;
    }

    if (poses.isEmpty) return SeatbeltStatus.unknown;

    final pose = poses.first;
    return _inferSeatbelt(pose);
  }

  /// Libera el detector de ML Kit. Llamar al finalizar el viaje.
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    await _detector.close();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Construcción del InputImage desde CameraImage
  // ─────────────────────────────────────────────────────────────────────────

  InputImage? _buildInputImage(
    CameraImage image,
    InputImageRotation rotation,
  ) {
    final format = _resolveFormat(image.format.group);
    if (format == null) return null;

    // Para YUV420 usamos el plano Y completo (luma) — suficiente para pose.
    final bytes = _concatenatePlanes(image.planes);

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  InputImageFormat? _resolveFormat(ImageFormatGroup group) {
    switch (group) {
      case ImageFormatGroup.yuv420:
        return InputImageFormat.yuv_420_888;
      case ImageFormatGroup.bgra8888:
        return InputImageFormat.bgra8888;
      default:
        return null;
    }
  }

  /// Concatena todos los planos del [CameraImage] en un único [Uint8List].
  Uint8List _concatenatePlanes(List<Plane> planes) {
    int totalLength = 0;
    for (final plane in planes) {
      totalLength += plane.bytes.length;
    }
    final buffer = Uint8List(totalLength);
    int offset = 0;
    for (final plane in planes) {
      buffer.setRange(offset, offset + plane.bytes.length, plane.bytes);
      offset += plane.bytes.length;
    }
    return buffer;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Lógica de inferencia de cinturón
  // ─────────────────────────────────────────────────────────────────────────

  SeatbeltStatus _inferSeatbelt(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return SeatbeltStatus.unknown;
    }

    // Verificar confianza mínima en todos los landmarks clave.
    if (leftShoulder.likelihood < _minLikelihood ||
        rightShoulder.likelihood < _minLikelihood ||
        leftHip.likelihood < _minLikelihood ||
        rightHip.likelihood < _minLikelihood) {
      return SeatbeltStatus.unknown;
    }

    // Normalizar las coordenadas X por el rango de hombros para hacerlo
    // independiente de la distancia a la cámara.
    final shoulderWidth = (rightShoulder.x - leftShoulder.x).abs();
    if (shoulderWidth < 1.0) return SeatbeltStatus.unknown;

    // Delta X normalizado entre hombro izquierdo y cadera izquierda.
    // Con cinturón puesto: el hombro izquierdo está desplazado a la derecha
    // respecto a la cadera izquierda (la banda tira hacia el centro).
    // En coordenadas de imagen: X crece hacia la derecha.
    // Cámara frontal espejada: el hombro izquierdo del conductor aparece
    // a la DERECHA en imagen => leftShoulder.x > leftHip.x cuando hay cinturón.
    final leftDeltaX = (leftShoulder.x - leftHip.x) / shoulderWidth;

    // Delta X normalizado en el lado derecho (control): sin cinturón, el
    // hombro derecho y la cadera derecha deben estar alineados verticalmente.
    final rightDeltaX = (rightShoulder.x - rightHip.x) / shoulderWidth;

    // La asimetría diagonal es la diferencia entre los dos deltas.
    // Con cinturón: leftDeltaX es positivo y mayor que rightDeltaX.
    final asymmetry = leftDeltaX - rightDeltaX;

    if (asymmetry > diagonalThreshold) {
      return SeatbeltStatus.detected;
    } else if (asymmetry < -diagonalThreshold) {
      // Asimetría inversa — cinturón en hombro derecho (posición inusual) o
      // conductor girado. Se interpreta igualmente como detectado.
      return SeatbeltStatus.detected;
    } else {
      return SeatbeltStatus.notDetected;
    }
  }
}
