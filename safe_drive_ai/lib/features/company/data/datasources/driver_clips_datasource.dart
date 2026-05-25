import '../models/driver_clip_model.dart';

abstract class DriverClipsDataSource {
  Future<List<DriverClipModel>> listDriverClips({
    required String driverId,
    required int pageSize,
    String? pageToken,
  });

  Future<String> getClipDownloadUrl(String firebaseStoragePath);
}
