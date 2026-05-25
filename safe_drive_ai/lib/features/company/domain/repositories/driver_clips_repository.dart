import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/video_clip_entity.dart';

abstract class DriverClipsRepository {
  Future<Either<Failure, List<VideoClipEntity>>> fetchDriverClips({
    required String driverId,
    required int pageSize,
    String? pageToken,
  });

  Future<Either<Failure, String>> getClipDownloadUrl(
    String firebaseStoragePath,
  );
}
