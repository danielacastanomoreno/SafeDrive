import '../../domain/entities/video_clip_entity.dart';

class DriverClipModel extends VideoClipEntity {
  const DriverClipModel({
    required super.id,
    required super.uploadedAt,
    required super.firebaseStoragePath,
    required super.eventType,
  });

  factory DriverClipModel.fromStorageItem({
    required String id,
    required DateTime uploadedAt,
    required String firebaseStoragePath,
  }) {
    return DriverClipModel(
      id: id,
      uploadedAt: uploadedAt,
      firebaseStoragePath: firebaseStoragePath,
      eventType: _parseEventType(id),
    );
  }

  // Filename format: trip_<tripId>_nivel1|nivel2|seatbelt_<timestamp>_chunk<n>.mp4
  static ClipEventType _parseEventType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.contains('nivel2')) return ClipEventType.drowsinessLevel2;
    if (lower.contains('nivel1')) return ClipEventType.drowsinessLevel1;
    if (lower.contains('seatbelt') || lower.contains('cinturon')) {
      return ClipEventType.seatbeltNotDetected;
    }
    return ClipEventType.unknown;
  }
}
