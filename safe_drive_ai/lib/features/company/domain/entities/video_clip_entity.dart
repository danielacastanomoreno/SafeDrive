import 'package:equatable/equatable.dart';

enum ClipEventType {
  drowsinessLevel1,
  drowsinessLevel2,
  seatbeltNotDetected,
  unknown;

  String get displayName {
    switch (this) {
      case ClipEventType.drowsinessLevel1:
        return 'Somnolencia nivel 1';
      case ClipEventType.drowsinessLevel2:
        return 'Somnolencia nivel 2';
      case ClipEventType.seatbeltNotDetected:
        return 'Cinturón no detectado';
      case ClipEventType.unknown:
        return 'Evento desconocido';
    }
  }
}

class VideoClipEntity extends Equatable {
  final String id;
  final DateTime uploadedAt;
  final String firebaseStoragePath;
  final ClipEventType eventType;

  const VideoClipEntity({
    required this.id,
    required this.uploadedAt,
    required this.firebaseStoragePath,
    required this.eventType,
  });

  @override
  List<Object?> get props => [id, uploadedAt, firebaseStoragePath, eventType];
}
