import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/driver_clip_model.dart';
import 'driver_clips_datasource.dart';

class DriverClipsDataSourceImpl implements DriverClipsDataSource {
  final FirebaseStorage _firebaseStorage;

  const DriverClipsDataSourceImpl({required FirebaseStorage firebaseStorage})
      : _firebaseStorage = firebaseStorage;

  @override
  Future<List<DriverClipModel>> listDriverClips({
    required String driverId,
    required int pageSize,
    String? pageToken,
  }) async {
    try {
      final ref = _firebaseStorage.ref('drivers/$driverId/clips');

      final listResult = await ref.listAll();

      // Convert storage items to models
      List<DriverClipModel> clips = [];
      for (final item in listResult.items) {
        final metadata = await item.getMetadata();
        clips.add(
          DriverClipModel.fromStorageItem(
            id: item.name,
            uploadedAt: metadata.updated ?? DateTime.now(),
            firebaseStoragePath: item.fullPath,
          ),
        );
      }

      // Sort by uploadedAt descending (newest first)
      clips.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      // Simple pagination (20 items at a time)
      int startIndex = 0;
      if (pageToken != null && pageToken.isNotEmpty) {
        startIndex = int.tryParse(pageToken) ?? 0;
      }
      int endIndex = (startIndex + pageSize).clamp(0, clips.length);

      return clips.sublist(startIndex, endIndex);
    } catch (e) {
      throw DataSourceException(e.toString());
    }
  }

  @override
  Future<String> getClipDownloadUrl(String firebaseStoragePath) async {
    try {
      final ref = _firebaseStorage.ref(firebaseStoragePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw DataSourceException(e.toString());
    }
  }
}
