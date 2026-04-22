import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Resultado del análisis de somnolencia por frame.
class DrowsinessFrameResult {
  const DrowsinessFrameResult({
    required this.faceDetected,
    required this.eyesClosed,
    required this.yawning,
    this.averageEyeOpenProbability,
    this.mouthAspectRatio,
  });

  const DrowsinessFrameResult.unknown()
      : faceDetected = false,
        eyesClosed = false,
        yawning = false,
        averageEyeOpenProbability = null,
        mouthAspectRatio = null;

  final bool faceDetected;
  final bool eyesClosed;
  final bool yawning;
  final double? averageEyeOpenProbability;
  final double? mouthAspectRatio;
}

/// Servicio de detección de somnolencia con ML Kit Face Detection.
///
/// Señales usadas:
/// - Ojos cerrados (probabilidad de apertura de ojos).
/// - Bostezo (apertura relativa de labios, tipo MAR simplificado).
class DrowsinessDetectionService {
  DrowsinessDetectionService({
    this.eyeOpenThreshold = 0.35,
    this.yawnThreshold = 0.30,
  }) : _detector = FaceDetector(
          options: FaceDetectorOptions(
            enableClassification: true,
            enableLandmarks: true,
            enableContours: true,
            enableTracking: true,
            minFaceSize: 0.15,
            performanceMode: FaceDetectorMode.fast,
          ),
        );

  /// Umbral por debajo del cual consideramos ojos cerrados.
  final double eyeOpenThreshold;

  /// Umbral de apertura bucal relativa para considerar bostezo.
  final double yawnThreshold;

  final FaceDetector _detector;
  bool _isClosed = false;

  Future<DrowsinessFrameResult> processImage(
    CameraImage image,
    InputImageRotation imageRotation,
  ) async {
    if (_isClosed) return const DrowsinessFrameResult.unknown();

    final inputImage = _buildInputImage(image, imageRotation);
    if (inputImage == null) return const DrowsinessFrameResult.unknown();

    List<Face> faces;
    try {
      faces = await _detector.processImage(inputImage);
    } catch (_) {
      return const DrowsinessFrameResult.unknown();
    }

    if (faces.isEmpty) {
      return const DrowsinessFrameResult.unknown();
    }

    final face = _largestFace(faces);
    if (face == null) {
      return const DrowsinessFrameResult.unknown();
    }

    final leftEyeOpen = face.leftEyeOpenProbability;
    final rightEyeOpen = face.rightEyeOpenProbability;

    double? averageEyeOpenProbability;
    if (leftEyeOpen != null && rightEyeOpen != null) {
      averageEyeOpenProbability = (leftEyeOpen + rightEyeOpen) / 2;
    } else if (leftEyeOpen != null) {
      averageEyeOpenProbability = leftEyeOpen;
    } else if (rightEyeOpen != null) {
      averageEyeOpenProbability = rightEyeOpen;
    }

    final bool eyesClosed;
    if (leftEyeOpen != null && rightEyeOpen != null) {
      eyesClosed =
          leftEyeOpen < eyeOpenThreshold && rightEyeOpen < eyeOpenThreshold;
    } else {
      eyesClosed = averageEyeOpenProbability != null &&
          averageEyeOpenProbability < eyeOpenThreshold;
    }

    final mar = _computeMouthAspectRatio(face);
    final yawning = mar != null && mar > yawnThreshold;

    return DrowsinessFrameResult(
      faceDetected: true,
      eyesClosed: eyesClosed,
      yawning: yawning,
      averageEyeOpenProbability: averageEyeOpenProbability,
      mouthAspectRatio: mar,
    );
  }

  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    await _detector.close();
  }

  Face? _largestFace(List<Face> faces) {
    Face? selected;
    double largestArea = 0;

    for (final face in faces) {
      final rect = face.boundingBox;
      final area = rect.width * rect.height;
      if (area > largestArea) {
        largestArea = area;
        selected = face;
      }
    }

    return selected;
  }

  double? _computeMouthAspectRatio(Face face) {
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth]?.position;
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth]?.position;

    final upperLip = face.contours[FaceContourType.upperLipTop]?.points;
    final lowerLip = face.contours[FaceContourType.lowerLipBottom]?.points;

    if (leftMouth == null ||
        rightMouth == null ||
        upperLip == null ||
        lowerLip == null ||
        upperLip.isEmpty ||
        lowerLip.isEmpty) {
      return null;
    }

    final mouthWidth = _distance(
      leftMouth.x.toDouble(),
      leftMouth.y.toDouble(),
      rightMouth.x.toDouble(),
      rightMouth.y.toDouble(),
    );
    if (mouthWidth < 1) return null;

    final upperY =
        upperLip.map((point) => point.y.toDouble()).reduce((a, b) => a + b) /
            upperLip.length;
    final lowerY =
        lowerLip.map((point) => point.y.toDouble()).reduce((a, b) => a + b) /
            lowerLip.length;

    final mouthOpen = (lowerY - upperY).abs();
    return mouthOpen / mouthWidth;
  }

  double _distance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return sqrt(dx * dx + dy * dy);
  }

  InputImage? _buildInputImage(
    CameraImage image,
    InputImageRotation rotation,
  ) {
    final format = _resolveFormat(image.format.group);
    if (format == null) return null;

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
}
